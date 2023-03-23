import ballerina/http;
import ballerina/io;
import ballerina/os;
import ballerina/time;

listener http:Listener httpListener =new (8080);
string API_KEY = os:getEnv("API_KEY");

http:Client github = check new ("https://api.github.com");

map<string> headers = {
    "Accept": "application/vnd.github.v3+json",
    "Authorization": "Bearer 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",
    "X-GitHub-Api-Version":"2022-11-28"
};

service / on httpListener {
    resource function get greeting() returns string {
        return "Hello,World";
    }

}


service /primitive on httpListener {

    resource function get getLinesOfCode(string ownername, string reponame) returns json|error {

        json data;
        json returnData;
        http:Client codetabsAPI = check new ("https://api.codetabs.com");

        do {
            data = check codetabsAPI->get("/v1/loc?github=" + ownername + "/" + reponame);
            io:println(data);
            return data;
        } on fail var e {
            returnData = {"message": e.toString()};
            return returnData; 
        }
    }

    resource function get getCommitCount(string ownername, string reponame) returns json|error {

        json[] data;
        json returnData;
        do {
            data = check github->get("/repos/" + ownername + "/" + reponame + "/commits", headers);
            returnData = {
                ownername: ownername,
                reponame: reponame,
                commitCount: data.length()
            };
        } on fail var e {
            returnData = {"message": e.toString()};
        }

        return returnData;
    }


    resource function get getPullRequestCount(string ownername, string reponame) returns json|error {

        json[] data;
        json returnData;
        do {
            data = check github->get("/repos/" + ownername + "/" + reponame + "/pulls", headers);
            returnData = {
                ownername: ownername,
                reponame: reponame,
                PullRequestCount: data.length()
                
            
            };
        } on fail var e {
            returnData = {"message": e.toString()};
        }

        return returnData;
    }

}

service /complex on httpListener {
    resource function get getMeanLeadFixTime(string ownername, string reponame) returns json|error {
        
        json[] data;
        json returnData;
        int fixTime=0;
        
        do{
        data = check github->get("/repos/" + ownername + "/" + reponame + "/issues?state=closed", headers);

        foreach json item in data{
            time:Utc t1;
            time:Utc t2;
            do{
                string openedTime = check item.created_at;
                t1 = check time:utcFromString(openedTime);
            }
                    
            do{
                string closedTime = check item.closed_at;
                t2= check time:utcFromString(closedTime);
                io:println(t2[0]-t1[0]);
                fixTime+= (t2[0]-t1[0]);
                
            }on fail {
                continue;
            }
        
            
        }
            
            int meanLeadTime = fixTime/data.length();
            io:println("Mean Lead Time to Fix Isssue = ",meanLeadTime);
            returnData = {
                ownername: ownername,
                reponame: reponame
            };

        } on fail var e {
            returnData = {"message": e.toString()};
        }

        return returnData;
    }

}
