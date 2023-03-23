
//import ballerina/io;
import ballerina/http;
listener http:Listener httpListener =new (8080);
map<string> headers = {
    "Accept": "application/vnd.github.v3+json",
    "Authorization": "Bearer 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",
    "X-GitHub-Api-Version":"2022-11-28"
};

 http:Client github = check new ("https://api.github.com");
 service /getIssues on httpListener {

resource function get getTotalIssues(string ownername, string reponame) returns json|error {

        json[] data =[];
        json returnData;
        do {
            
            data = check github->get("/repos/" + ownername + "/" + reponame + "/issues");
            returnData = {
                ownername: ownername,
                reponame: reponame,
                issues: data.length()
                
            };
        } on fail var e {
            returnData = {"message": e.toString()};
        }

        return returnData;
    }
 }
