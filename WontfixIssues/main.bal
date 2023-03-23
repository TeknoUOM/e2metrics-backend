
//import ballerina/io;
import ballerina/http;
listener http:Listener httpListener =new (8080);
map<string> headers = {
    "Accept": "application/vnd.github.v3+json",
    "Authorization": "Bearer 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",
    "X-GitHub-Api-Version":"2022-11-28"
};

 http:Client github = check new ("https://api.github.com");
 service /getWontfixIssues on httpListener {

resource function get getWontfixTotalIssues(string ownername, string reponame) returns json|error {

        json[] data =[];
        json returnData;
        do {
            
            data = check github->get("/repos/" + ownername + "/" + reponame + "/issues?state=closed&labels=wontfix");
            returnData = {
                ownername: ownername,
                reponame: reponame,
                wontfixissues: data.length()
                
            };
        } on fail var e {
            returnData = {"message": e.toString()};
        }

        return returnData;
    }
 }
