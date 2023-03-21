import ballerina/http;
import ballerina/io;
import ballerina/os;

listener http:Listener httpListener =new (8084);
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



    resource function get getWeeklyCommitCount(string ownername, string reponame) returns json|error {

        map<json> data;
        json returnData;
        do {
            data = check github->get("/repos/" + ownername + "/" + reponame + "/stats/participation", headers);
            json[] temp  = <json[]>data.get("all");
            returnData = {
                ownername: ownername,
                reponame: reponame,
                LastWeekCommitCount:temp[temp.length()-1]
            };
        } on fail var e {
            io:print(e);
            returnData = {"message": e.toString()};
        }

        return returnData;
    }


    resource function get getOpenedIssues(string ownername, string reponame) returns json|error {

        json[] data;
        json returnData;
        do {
            data = check github->get("/repos/" + ownername + "/" + reponame + "/issues?state=open", headers);
            returnData = {
                ownername: ownername,
                reponame: reponame,
                OpenedIssuesCount: data.length()
                
            
            };
        } on fail var e {
            returnData = {"message": e.toString()};
        }

        return returnData;
    }

}