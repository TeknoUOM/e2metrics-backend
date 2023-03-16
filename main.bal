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
    "X-GitHub-Api-Version":"2022-11-28"
};

type Language record {
    string language;
    int files;
    int lines;
    int blanks;
    int comments;
    int linesOfCode;
};

type Code record {
    int linesOfCode;
};


service / on httpListener {
    resource function get greeting() returns string {
        return "Hello,World";
    }

}


service /primitive on httpListener {

    // resource function get getLinesOfCode(string ownername, string reponame) returns json|error {

    //     Language[] data;
    //     json returnData;
    //     Code[] code;

    //     do {
    //         data = check codetabsAPI->get("/v1/loc/?github=" + ownername + "/" + reponame);
    //         returnData={
    //             "ownername":ownername,
    //             "reponame":reponame
    //         };

    //         foreach Language lang in data{
    //             string language=lang.language;
    //             return {language:lang.linesOfCode};
    //         } 
    //     } on fail var e {
    //         returnData = {"message": e.toString()};
             
    //     }
    //     return returnData;
    // }

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

}