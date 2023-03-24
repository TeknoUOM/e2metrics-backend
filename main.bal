import ballerina/http;
import ballerina/io;
import ballerina/os;
import ballerina/mime;
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


http:Client asgardeoClient = check new ("https://api.asgardeo.io",httpVersion = http:HTTP_1_1);

service /primitive2 on httpListener {

    resource function get userDetails() returns json|error {
        
        string clientID="2TvAgxdthV3fBr4bAWFvPqkwd54a";
        string clientSecrat="lMrOSM2dg1yLIi4FL08QBIoAd_Ma";

        string combineKey = clientID+":"+clientSecrat;

        byte[] keyInBytes = combineKey.toBytes();
        string encodedString = keyInBytes.toBase64();

        string accessToken;

        do{
            json response = check asgardeoClient->post("/t/tekno/oauth2/token",
            {
                "scope": "internal_login",
                "grant_type": "client_credentials"
            },
        {
                "Authorization": "Basic " + encodedString
            },
        mime:APPLICATION_FORM_URLENCODED
        );

            accessToken = check response.access_token;
        }on fail var err {
            io:println(err);
        }


        map<string> asgardeoClientHeaders = {
            "Authorization": "Bearer " + accessToken
        };

        json returnData = {};

        do {
            json data = check asgardeoClient->get("/t/tekno/scim2/Me",asgardeoClientHeaders);
            returnData = {
                name: data
            };
        } on fail var e {
            returnData={"message":e.toString()};
        }
        return returnData;
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


service /complex on httpListener {
    resource function get getMeanPullRequestResponseTime(string ownername, string reponame) returns json|error {
        
        json[] data;
        json returnData;
        int ResponseTime=0;
        
        do{            
            data = check github->get("/repos/" + ownername + "/" + reponame + "/pulls", headers);


        foreach json item in data{
            time:Utc t1;
            time:Utc t2;
            do{
                string createdTime = check item.created_at;
             t1 = check time:utcFromString(createdTime);
            }
                    
            do{
                string updatedTime = check item.updated_at;
                t2= check time:utcFromString(updatedTime);
                io:println(t2[0] - t1[0]);
                ResponseTime+= (t2[0] - t1[0]);
                
            }on fail {
                continue;
            }
        
            
        }
            
            int meanResponseTime = (ResponseTime/data.length());



            string timeInHours = (meanResponseTime/3600).toString();
            string timeinMinutes = ((meanResponseTime%3600)/60).toString();
            string timeinSeconds = (meanResponseTime%60).toString();





            io:println("Mean Lead Time respond for a pull request = ",meanResponseTime);
            returnData = {
                meanResponseTimeInFormat :timeInHours + "hrs  " + timeinMinutes+ "min "  + timeinSeconds + "secs",
                ownername: ownername,
                reponame: reponame
            };

        } on fail var e {
            returnData = {"message": e.toString()};
        }

        return returnData;
    }

}