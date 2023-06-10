import ballerina/http;
import ballerina/os;
import ballerina/sql;
import ballerinax/mysql;
import ballerina/io;
import ballerinax/mysql.driver as _;
import ballerina/time;
import ballerina/task;
import ballerina/crypto;

mysql:Options mysqlOptions = {
    ssl: {
        mode: mysql:SSL_PREFERRED
    },
    connectTimeout: 10
};
mysql:Client dbClient = check new (hostname, username, password, "E2Metrices", port);

listener http:Listener httpListener = new (8080);
string API_KEY = os:getEnv("API_KEY");

http:Client github = check new ("https://api.github.com");
http:Client codetabsAPI = check new ("https://api.codetabs.com");

type Label record {
    string 'name?;
};

type pull_request record {
    string|() 'merged_at?;
};

type Issues record {
    string 'url;
    Label[] 'labels;
    pull_request 'pull_request?;
    string 'events_url?;
    string 'created_at?;
};

type Pulls record {
    string|() 'created_at?;
};

type Event record {
    string|() 'created_at?;
};

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        allowCredentials: true,
        allowMethods: ["GET", "POST", "OPTIONS", "PUT"]
    }
}
service / on httpListener {
    resource function get metrics/getIssuesFixingFrequency(string ownername, string reponame, string accessToken) returns json|error {
        json returnData;
        float IssuesFixingFrequency;
        do {
            IssuesFixingFrequency = check getIssuesFixingFrequency(ownername, reponame, accessToken);
            returnData = {
                "ownername": ownername,
                "reponame": reponame,
                "IssuesFixingFrequency": IssuesFixingFrequency
            };

        } on fail var e {
            return e;
        }
        return returnData;
    }

    resource function get metrics/getBugFixRatio(string ownername, string reponame, string accessToken) returns json|error {
        json returnData;
        do {
            float BugFixRatio = check getBugFixRatio(ownername, reponame, accessToken);
            returnData = {
                "ownername": ownername,
                "reponame": reponame,
                "BugFixRatio": BugFixRatio
            };
            return returnData;
        } on fail var e {
            return e;
        }

    }

    resource function get metrics/getMeanLeadFixTime(string ownername, string reponame, string accessToken) returns json|error {

        json returnData;

        do {

            float meanLeadTime = check getMeanLeadFixTime(ownername, reponame, accessToken);
            returnData = {
                ownername: ownername,
                reponame: reponame,
                meanLeadTime: meanLeadTime
            };
            return returnData;

        } on fail var e {
            return e;
        }
    }

    resource function get metrics/getPullRequestFrequency(string ownername, string reponame, string accessToken) returns json|error {

        json returnData;

        do {

            int frequency = check getPullRequestFrequency(ownername, reponame, accessToken);

            returnData = {
                ownername: ownername,
                reponame: reponame,
                pullRequestfrequency: frequency

            };
            return returnData;
        } on fail var e {
            return e;
        }

    }
    resource function get metrics/getLinesOfCode(string ownername, string reponame, string accessToken) returns json|error {

        do {
            json returnData = check getLinesOfCode(ownername, reponame, accessToken);
            returnData = {
                "ownername": ownername,
                "reponame": reponame,
                "totalNumberOfLines": check returnData.totalNumberOfLines,
                "languages": check returnData.languages
            };
            return returnData;
        } on fail var e {
            return e;
        }

    }
    resource function get metrics/getWeeklyCommitCount(string ownername, string reponame, string accessToken) returns json|error {

        json returnData;
        do {
            json LastWeekCommitCount = check getWeeklyCommitCount(ownername, reponame, accessToken);
            returnData = {
                ownername: ownername,
                reponame: reponame,
                LastWeekCommitCount: LastWeekCommitCount
            };
            return returnData;
        } on fail var e {
            return e;
        }

    }

    resource function get metrics/getOpenedIssuesCount(string ownername, string reponame, string accessToken) returns json|error {

        json returnData;
        do {
            int OpenedIssuesCount = check getOpenedIssuesCount(ownername, reponame, accessToken);
            returnData = {
                ownername: ownername,
                reponame: reponame,
                OpenedIssuesCount: OpenedIssuesCount

            };
            return returnData;
        } on fail var e {
            return e;
        }

    }
    resource function get metrics/getAllIssuesCount(string ownername, string reponame, string accessToken) returns json|error {

        json returnData;
        do {
            int AllIssuesCount = check getAllIssuesCount(ownername, reponame, accessToken);
            returnData = {
                ownername: ownername,
                reponame: reponame,
                AllIssuesCount: AllIssuesCount

            };
            return returnData;
        } on fail var e {
            return e;
        }

    }
    resource function get metrics/getWontFixIssuesRatio(string ownername, string reponame, string accessToken) returns json|error {

        json returnData;
        do {
            float WontFixIssuesRatio = check getWontFixIssuesRatio(ownername, reponame, accessToken);
            returnData = {
                ownername: ownername,
                reponame: reponame,
                WontFixIssuesRatio: WontFixIssuesRatio

            };
            return returnData;
        } on fail var e {
            return e;
        }

    }
    resource function get metrics/getMeanPullRequestResponseTime(string ownername, string reponame, string accessToken) returns json|error {

        json returnData;
        do {
            int meanResponseTime = check getMeanPullRequestResponseTime(ownername, reponame, accessToken);

            returnData = {
                meanResponseTime: meanResponseTime,
                ownername: ownername,
                reponame: reponame
            };
            return returnData;

        } on fail var e {
            return e;
        }
    }
    resource function get metrics/getPullRequestCount(string ownername, string reponame, string accessToken) returns json|error {

        json returnData;
        do {
            int pullRequestCount = check getPullRequestCount(ownername, reponame, accessToken);
            returnData = {
                ownername: ownername,
                reponame: reponame,
                PullRequestCount: pullRequestCount

            };
            return returnData;
        } on fail var e {
            return e;
        }
    }
    resource function get metrics/getMeanLeadTimeForPulls(string ownername, string reponame, string accessToken) returns json|error {

        json returnData;

        do {
            float MeanLeadTime = check getMeanLeadTimeForPulls(ownername, reponame, accessToken);
            returnData = {
                ownername: ownername,
                reponame: reponame,
                MeanLeadTime: MeanLeadTime
            };
            return returnData;
        } on fail var e {
            return e;
        }
    }

    resource function get metrics/getResponseTimeforIssue(string ownername, string reponame, string accessToken) returns json|error {

        json returnData;

        do {
            float responseTimeforIssue = check getResponseTimeforIssue(ownername, reponame, accessToken);
            returnData = {
                ownername: ownername,
                reponame: reponame,
                responseTimeforIssue: responseTimeforIssue
            };
            return returnData;
        } on fail var e {
            return e;
        }

    }

    resource function get metrics/getPerfomances(string userId) returns Perfomance[]|error {

        stream<Perfomance, sql:Error?> Stream = dbClient->query(`SELECT * FROM DailyPerfomance ORDER BY Date DESC LIMIT 1`);

        return from Perfomance perfomance in Stream
            select perfomance;
    }
    resource function post payment/savePayment(@http:Payload map<json> reqBody) returns json|error {
        string timestamp = check reqBody.timestamp;
        string id = check reqBody.id;
        string userId = check reqBody.userId;
        float amountValue = check reqBody.amount.value;
        string amountCurrencyCode = check reqBody.amount.currency_code;
        string subscription = check reqBody.subscription;
        do {
            json returnData = check savePayment(timestamp, id, userId, amountValue, amountCurrencyCode, subscription);
            return returnData;
        } on fail var e {
            return e;
        }
    }
    resource function post user/authorizeToGithub(@http:Payload map<json> reqBody) returns json|error {

        string code = check reqBody.code;
        string userId = check reqBody.userId;
        json returnData = {};
        do {
            json response = check authorizeToGithub(code, userId);

            returnData = {
                res: response
            };
            return returnData;

        } on fail var err {
            return err;
        }

    }

    resource function get user/getUserAllRepos(string userId) returns json[]|error {
        json[] response = [];
        do {
            response = check getUserAllRepos(userId);
            return response;
        } on fail error e {
            return e;
        }
    }

    resource function post user/addRepo(@http:Payload UserRequest userRequest) returns json|error {
        json response;
        do {
            response = check addRepo(userRequest);
            return response;
        } on fail var e {
            return e;
        }
    }
    resource function get user/getUserGithubToken(string userId) returns json|error {
        json response;
        do {
            string ghToken = check getUserGithubToken(userId);

            response = {
                "userId": userId,
                "ghToken": ghToken
            };
            return response;
        } on fail var e {
            return e;
        }

    }

    resource function put user/changeUserGroup(string userId, string groupName) returns json|error {
        User user = check getUserById(userId);
        Group[] groups = user?.groups ?: [];
        if (user?.'groups != ()) {
            foreach Group group in groups {
                string tempGroupName = <string>group.'display;
                tempGroupName = tempGroupName.substring(8);
                _ = check removeUserFromGroup(userId, tempGroupName);
            }
        }
        json|error response = check addUserToGroup(userId, groupName);
        return response;
    }

    resource function post user/addUserToGroup(string userId, @http:Payload string groupName) returns json|error {
        json|error response = addUserToGroup(userId, groupName);
        return response;
    }

    resource function delete user/removeUserGroup(string userId, @http:Payload string groupName) returns json|error {
        json|error response = removeUserFromGroup(userId, groupName);
        return response;
    }

}

type RepositoriesJOINUser record {
    string 'Ownername;
    string 'Reponame;
    string 'UserID;
    byte[] 'GH_AccessToken;
};

class CalculateMetricsPeriodically {

    *task:Job;

    public function execute() {
        do {

            stream<RepositoriesJOINUser, sql:Error?> resultStream = dbClient->query(`SELECT Repositories.Reponame, Repositories.Ownername, Users.GH_AccessToken, Users.UserID FROM Users INNER JOIN Repositories ON Users.UserID=Repositories.UserId;`);
            check from RepositoriesJOINUser row in resultStream
                do {
                    byte[] plainText = check crypto:decryptAesCbc(row.GH_AccessToken, encryptkey, initialVector);
                    string accessToken = check string:fromBytes(plainText);
                    setRepositoryPerfomance(row.'Ownername, row.'Reponame, row.'UserID, accessToken);
                };
        } on fail error e {
            io:println(e.message());
        }

    }
}

time:Utc currentUtc = time:utcNow();
time:Utc newTime = time:utcAddSeconds(currentUtc, 10);
time:Civil time = time:utcToCivil(newTime);

task:JobId result = check task:scheduleJobRecurByFrequency(new CalculateMetricsPeriodically(), 86400, 10, time);

