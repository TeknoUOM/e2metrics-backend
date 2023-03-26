
//import ballerina/io;
import ballerina/http;
listener http:Listener httpListener =new (8080);
map<string> headers = {
    "Accept": "application/vnd.github.v3+json",
    "Authorization": "Bearer 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",
    "X-GitHub-Api-Version":"2022-11-28"
};

 http:Client github = check new ("https://api.github.com");
 service /getWontfixIssueRatio on httpListener {

resource function get getWontfixIssueRatio(string ownername, string reponame) returns json|error {

        json[] data =[];
        json returnData;
        int wontfixissues;
        int tIssues;
        int closedIssues;
        float wontfixIssueRatioByTotalIssues;
        float wontfixIssueRatioByClosedIssues;

do {
            
            data = check github->get("/repos/" + ownername + "/" + reponame + "/issues");
           
            tIssues=data.length();

            returnData = {
                ownername: ownername,
                reponame: reponame,
                Tissues: tIssues
                
            };
            do {
            
            data = check github->get("/repos/" + ownername + "/" + reponame + "/issues?state=closed");
            closedIssues=data.length();

            returnData = {
                ownername: ownername,
                reponame: reponame,
                closedIssues: closedIssues
                
            };

        do {
            data = check github->get("/repos/" + ownername + "/" + reponame + "/issues?state=closed&labels=wontfix");
            wontfixissues=data.length();
            returnData = {
                ownername: ownername,
                reponame: reponame,
                wontfixissues: wontfixissues
                
            };
               
          wontfixIssueRatioByTotalIssues = <float> wontfixissues / tIssues;
          wontfixIssueRatioByClosedIssues= <float> wontfixissues/ closedIssues;
        do{
             returnData={
            wontfixIssueRatioByTotalIssues: wontfixIssueRatioByTotalIssues,
            wontfixIssueRatioByClosedIssues: wontfixIssueRatioByClosedIssues

         };

        } on fail var e {
            returnData = {"message": e.toString()
            };
        }

        return returnData;
    }
 }
 }
 } 
 }