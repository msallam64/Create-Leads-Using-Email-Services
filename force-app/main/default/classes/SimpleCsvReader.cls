public class SimpleCsvReader {
    
    private List<String> lines;
    public SimpleCsvReader(String csvdata){
        lines = csvdata.split('\n');
    }
    
    public List<String> readLine(){
        
        if(lines.isEmpty()){
            return null;
        }
        
        String line = lines.remove(0);
        List<String> colms = new List<String>();
        Integer start =0;
        while(start < line.length()){
            Integer endline = line.indexOf(',', start);
            if (endline == -1) {
                endline = line.length();
            }
            colms.add(line.substring(start, endline));
            start = endline + 1;
        }
        return colms;
    }    
}