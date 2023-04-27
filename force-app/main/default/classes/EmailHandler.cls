global class EmailHandler implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        
        String leadCsvFile = null;
        System.debug(' email.binaryAttachments++' + email.binaryAttachments);
        
        try {
            for (Messaging.InboundEmail.BinaryAttachment att : email.binaryAttachments) {
                if (att.fileName.endsWith('.csv')) {
                    leadCsvFile = att.body.toString();
                    break;
                }
            }
        } catch (Exception e) {
            System.debug('Error reading email attachments: ' + e.getMessage());
            return result;
        }
        
        if (leadCsvFile == null) {
            return result;
        }
        
        SimpleCsvReader csvReader = new SimpleCsvReader(leadCsvFile);
        
        String[] headers = csvReader.readLine();        
        String[] data;
        
        List<Lead> leadsToInsert = new List<Lead>();
        
        String header = 'FirstName, LastName, Company, Status, Error \n';
        String finalCSV = header;
        while ((data = csvReader.readLine()) != null) {
            String FirstName = data[0];
            String LastName = data[1];
            String Company = data[2];
            String Status = data[3];
            
            Lead ld = new Lead(FirstName = FirstName, LastName = LastName, Company = Company, Status = Status);
            leadsToInsert.add(ld);
        }
        
        Database.SaveResult[] saveResult = Database.insert(leadsToInsert, false);
        Integer index = 0;
        
        for(Database.SaveResult sr : saveResult){
            String errormsg = '';
            if(!sr.isSuccess()) {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('Database Error: ' + err.getMessage());
                    errormsg += err.getMessage() + ';';
                }
            }
            
            String FirstName = leadsToInsert[index].FirstName;
            String LastName = leadsToInsert[index].LastName;
            String Company = leadsToInsert[index].Company;
            String Status = leadsToInsert[index].Status;
            
            String leadCsvString = '"' + FirstName + '","' + LastName + '","' + Company + '","' + Status + '","' + errormsg + '"\n'; 
            finalCSV += leadCsvString;
            index++;
        }
        
        System.debug('Final CSV: ' + finalCSV);
        
        Document newleadscsv = new Document(
            FolderId = UserInfo.getUserId(),
            Name = 'LeadErrors.csv',
            Body = Blob.valueOf(finalCSV)
        );
        insert newleadscsv;
        System.debug('CSV: ' + newleadscsv);
        
        String ErrorCsv = 'LeadErrorCsv.csv';
        String subject = 'Error Creating Leads';
        String body = 'Error Creating Leads. View CSV attachment for info.';
        String senderEmail = email.fromAddress;
        
        Messaging.SingleEmailMessage errorEmail = new Messaging.SingleEmailMessage(); 
        Messaging.EmailFileAttachment csvAttachment = new Messaging.EmailFileAttachment();
        csvAttachment.setFileName(ErrorCsv);
        csvAttachment.setBody(Blob.valueOf(finalCSV));
        errorEmail.setSubject(subject);
        errorEmail.setToAddresses(new String[] {senderEmail});
        errorEmail.setPlainTextBody(body);
        errorEmail.setFileAttachments(new Messaging.EmailFileAttachment[] {csvAttachment});
        Messaging.SendEmailResult[] emailResult = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {errorEmail});
        
        if (emailResult[0].isSuccess()) {
            System.debug('Email sent successfully.');
        } else {
            System.debug('Failed to send email: ' + emailResult[0].getErrors()[0].getMessage());
        }
        
        return result;
    }
}