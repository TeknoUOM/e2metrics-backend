import ballerina/http;
import ballerina/os;
import ballerina/sql;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;

mysql:Options mysqlOptions = {
    ssl: {
        mode: mysql:SSL_PREFERRED
    },
    connectTimeout: 10
};
mysql:Client|sql:Error dbClient =new (hostname,username,password,"", port);


listener http:Listener httpListener =new (8080);
string API_KEY = os:getEnv("API_KEY");

http:Client github = check new ("https://api.github.com");
http:Client codetabsAPI = check new ("https://api.codetabs.com");

map<string> headers = {
    "Accept": "application/vnd.github.v3+json",
    "Authorization": "Bearer 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",
    "X-GitHub-Api-Version": "2022-11-28"
};

service / on httpListener {
    resource function get greeting() returns string {
        return "Hello,World";
    }

}


service /primitive on httpListener {
    resource function get getLinesOfCode(string ownername, string reponame) returns json|error {
        json [] data;
        json returnData;
        int totalNumberOfLines = 0;
        json [] languages=[];

        do {
            data = check codetabsAPI->get("/v1/loc/?github=" + ownername + "/" + reponame);
            foreach var item in data {
                int linesOfCode = check item.linesOfCode;
                totalNumberOfLines += linesOfCode;
            }
            foreach var item in data {
                float lines = check item.lines;
                float ratio = (lines/totalNumberOfLines)*100;
                languages.push({
                    language: check item.language,
                    lines: check item.lines,
                    ratio: ratio
                });
            }
            returnData={
                "ownername":ownername,
                "reponame":reponame,
                "totalNumberOfLines":totalNumberOfLines,
                "languages":languages
            };
        } on fail var e {
            returnData = {"message": e.toString()};
             
        }
        return returnData;
    }

}

service /complex on httpListener {
    resource function get getIssuesFixingFrequency(string ownername, string reponame) returns json|error {
        json[] data;
        int totalIssuesCount=0;
        float fixedIssuesCount=0;
        json returnData;

        do {
            data = check github->get("/repos/" + ownername + "/" + reponame + "/issues", headers);
            totalIssuesCount=data.length();

            data = check github->get("/repos/" + ownername + "/" + reponame + "/issues?state=closed", headers);

            foreach json item in data {
                do {
                    var _ = check item.pull_request;
                    do {
                        var _ = check item.pull_request.merged_at;
                        fixedIssuesCount = fixedIssuesCount+1;
                    }
                } on fail {
                    continue;
                }
            }
            float  IssuesFixingFrequency =fixedIssuesCount/totalIssuesCount;

            returnData = {
                "ownername": ownername,
                "reponame": reponame,
                "IssuesFixingFrequency": IssuesFixingFrequency
            };
        } on fail var e {
            returnData = {"message": e.toString()};

        }
        return returnData;
    }

}

