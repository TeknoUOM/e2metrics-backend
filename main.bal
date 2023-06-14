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
        allowMethods: ["GET", "POST", "OPTIONS", "PUT", "DELETE"]
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

    resource function get metrics/setRepositoryPerfomance(string ownername, string reponame, string UserId, string accessToken) returns json|error {

        do {
            setRepositoryPerfomance(ownername, reponame, UserId, accessToken);

        } on fail var e {
            return e;
        }

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

    resource function get metrics/getCommitCount(string ownername, string reponame, string accessToken) returns json|error {

        json returnData;
        do {
            int commitCount = check getCommitCount(ownername, reponame, accessToken);
            returnData = {
                ownername: ownername,
                reponame: reponame,
                commitCount: commitCount
            };
        } on fail var e {
            returnData = {"message": e.toString()};
        }

        return returnData;
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

    resource function get metrics/getRepoLatestDailyPerfomance(string userId, string reponame, string ownername) returns Perfomance[]|error {
        mysql:Client dbClient = check new (hostname, username, password, "E2Metrices", port);

        stream<Perfomance, sql:Error?> Stream = dbClient->query(`SELECT * FROM DailyPerfomance WHERE Ownername=${ownername} AND Reponame=${reponame} AND UserId=${userId} ORDER BY Date DESC LIMIT 1`);
        sql:Error? close = dbClient.close();

        return from Perfomance perfomance in Stream
            select perfomance;

    }
    resource function get metrics/getRepoLatestMonthlyPerfomance(string userId, string reponame, string ownername) returns Perfomance[]|error {
        mysql:Client dbClient = check new (hostname, username, password, "E2Metrices", port);
        stream<Perfomance, sql:Error?> Stream = dbClient->query(`SELECT * FROM DailyPerfomance WHERE Ownername=${ownername} AND Reponame=${reponame} AND UserId=${userId} ORDER BY Date DESC LIMIT 30`);
        sql:Error? close = dbClient.close();
        return from Perfomance perfomance in Stream
            select perfomance;
    }
    resource function get metrics/getRepoLatestWeeklyPerfomance(string userId, string reponame, string ownername) returns Perfomance[]|error {
        mysql:Client dbClient = check new (hostname, username, password, "E2Metrices", port);
        stream<Perfomance, sql:Error?> Stream = dbClient->query(`SELECT * FROM DailyPerfomance WHERE Ownername=${ownername} AND Reponame=${reponame} AND UserId=${userId} ORDER BY Date DESC LIMIT 7`);
        sql:Error? close = dbClient.close();

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
    resource function get payment/savePayment(string userId) returns PaymentInDB[]|error {
        do {
            PaymentInDB[] returnData = check getUserPayments(userId);
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

    resource function post user/addRepo(@http:Payload UserRequest userRequest) returns sql:ExecutionResult|error {
        sql:ExecutionResult|sql:Error response;
        do {
            response = check addRepo(userRequest);
            return response;
        } on fail var e {
            return e;
        }
    }

    resource function delete user/removeRepo(@http:Payload UserRequest userRequest) returns sql:ExecutionResult|error {
        sql:ExecutionResult|sql:Error response;
        do {
            response = check removeRepo(userRequest.userId, userRequest.ghUser, userRequest.repo);
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

    resource function post user/addUserToGroup(string userId, string groupName) returns json|error {
        json|error response = addUserToGroup(userId, groupName);
        return response;
    }

    resource function delete user/removeUserGroup(string userId, string groupName) returns json|error {
        json|error response = removeUserFromGroup(userId, groupName);
        return response;
    }

    resource function post user/changePic(@http:Payload map<json> reqBody) returns sql:ExecutionResult|error {
        string imageURL = check reqBody.image;
        string userId = check reqBody.userId;
        do {
            sql:ExecutionResult|sql:Error result = check changePic(imageURL, userId);
            return result;
        }
        on fail var e {
            return e;
        }

    }

    resource function get user/getPic(string userId) returns json|error {
        byte[] response;

        do {
            response = check getPic(userId);
            return response;
        } on fail var e {
            return e;
        }
    }
    resource function get user/getUserDetails(string userId) returns json|error {

        do {
            json data = check getUserDetails(userId);
            return data;
        } on fail var e {
            return e;
        }
    }
    resource function post user/changeUserDetails(@http:Payload map<json> reqBody) returns json|error {
        string email = check reqBody.email;
        string firstName = check reqBody.firstName;
        string lastName = check reqBody.lastName;
        string mobile = check reqBody.mobile;
        string userId = check reqBody.userId;

        do {
            json data = check changeUserDetails(userId, email, mobile, firstName, lastName);
            return data;
        } on fail var e {
            return e;
        }
    }
    resource function get user/getAllUsers() returns json[]|error {

        do {
            json[] data = check getAllUsers();
            return data;
        } on fail var e {
            return e;
        }
    }
    resource function get user/getUsersRepotsStatus(string userId) returns int|error {

        do {
            int data = check getUserReportStatus(userId);
            return data;
        } on fail var e {
            return e;
        }
    }

    resource function post user/setUserReportStatus(@http:Payload map<json> reqBody) returns sql:ExecutionResult|error {

        string userId = check reqBody.userId;
        boolean isReportsEnable = check reqBody.isReportsEnable;

        do {
            sql:ExecutionResult data = check setUserReportStatus(userId, isReportsEnable);
            return data;
        } on fail var e {
            return e;
        }
    }
    resource function get user/getUserAlertLimits(string userId) returns AlertLimitsInDB[]|error {

        do {
            AlertLimitsInDB[] data = check getUserAlertLimits(userId);
            return data;
        } on fail var e {
            return e;
        }
    }
    resource function post user/setUserAlertLimits(@http:Payload map<json> reqBody) returns sql:ExecutionResult|error {
        string wontFixIssuesRatioString = check reqBody.wontFixIssuesRatio;
        float wontFixIssuesRatio = check float:fromString(wontFixIssuesRatioString);

        string weeklyCommitCountString = check reqBody.weeklyCommitCount;
        int weeklyCommitCount = check int:fromString(weeklyCommitCountString);

        string meanPullRequestResponseTimeString = check reqBody.meanPullRequestResponseTime;
        int meanPullRequestResponseTime = check int:fromString(meanPullRequestResponseTimeString);

        string meanLeadTimeForPullsString = check reqBody.meanLeadTimeForPulls;
        float meanLeadTimeForPulls = check float:fromString(meanLeadTimeForPullsString);

        string responseTimeforIssueString = check reqBody.responseTimeforIssue;
        float responseTimeforIssue = check float:fromString(responseTimeforIssueString);
        string userId = check reqBody.userId;
        do {
            sql:ExecutionResult data = check setUserAlertLimits(userId, wontFixIssuesRatio, weeklyCommitCount, meanPullRequestResponseTime, meanLeadTimeForPulls, responseTimeforIssue);
            return data;
        } on fail var e {
            return e;
        }
    }

    resource function get user/getUserAlerts(string userId) returns AlertsInDB[]|error {

        do {
            AlertsInDB[] data = check getUserAlerts(userId);
            return data;
        } on fail var e {
            return e;
        }
    }
    resource function post user/setUserAlerts(@http:Payload map<json> reqBody) returns sql:ExecutionResult|error {
        string userId = check reqBody.userId;
        string alert = check reqBody.alert;
        do {
            sql:ExecutionResult data = check setUserAlerts(userId, alert);
            return data;
        } on fail var e {
            return e;
        }
    }

    resource function post user/setUserAlertsIsShowed(@http:Payload map<json> reqBody) returns sql:ExecutionResult|error {
        string userId = check reqBody.userId;
        do {
            sql:ExecutionResult data = check setUserAlertsIsShowed(userId);
            return data;
        } on fail var e {
            return e;
        }
    }

    resource function get user/getUserLayout(string userId) returns json|error {

        do {
            json data = check getUserLayout(userId);
            return data;
        } on fail var e {
            return e;
        }
    }
    @http:ResourceConfig {
        cors: {
            allowOrigins: ["http://localhost:3000"],
            allowCredentials: true,
            allowMethods: ["GET", "POST", "OPTIONS", "PUT", "DELETE"]
        }
    }
    resource function port user/changeUserLayout(@http:Payload map<json> reqBody) returns sql:ExecutionResult|error {
        string userId = check reqBody.userId;
        string overviewlayout = check reqBody.overviewlayout;
        string comparisonLayout = check reqBody.comparisonLayout;
        string forecastLayout = check reqBody.forecastLayout;
        do {
            sql:ExecutionResult data = check changeUserLayout(overviewlayout, comparisonLayout, forecastLayout, userId);
            return data;
        } on fail var e {
            return e;
        }
    }
    resource function get user/getAllUserDetails() returns User[]|error {

        do {
            User[] data = check getAllUserDetails();
            return data;
        } on fail var e {
            return e;
        }
    }

    resource function get forecast/getForecast(string usreId, string ownername, string reponame) returns json[]|error {

        do {
            json[] data = check getForecast(usreId, ownername, reponame);
            return data;
        } on fail var e {
            return e;
        }
    }
    resource function get metrics/getMonthlyReport(string userId, string startDate, string endDate) returns Perfomance[]|error {
        do {
            Perfomance[] perfomance = check getMonthlyReport(userId, startDate, endDate);
            return perfomance;
        } on fail var e {
            return e;
        }

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
        time:Utc currentUtc = time:utcNow();
        time:Utc newTime = time:utcAddSeconds(currentUtc, 86390);
        time:Civil time = time:utcToCivil(newTime);

        do {
            task:JobId _ = check task:scheduleOneTimeJob(new CalculateMetricsPeriodically(), time);
        } on fail var e {
            io:println(e.message());
        }
        mysql:Client dbClient;
        do {
            dbClient = check new (hostname, username, password, "E2Metrices", port);
            stream<RepositoriesJOINUser, sql:Error?> resultStream = dbClient->query(`SELECT Repositories.Reponame, Repositories.Ownername, Users.GH_AccessToken, Users.UserID FROM Users INNER JOIN Repositories ON Users.UserID=Repositories.UserId;`);
            sql:Error? close = dbClient.close();
            check from RepositoriesJOINUser row in resultStream
                do {
                    byte[] plainText = check crypto:decryptAesCbc(row.GH_AccessToken, encryptkey, initialVector);
                    string accessToken = check string:fromBytes(plainText);
                    setRepositoryPerfomance(row.'Ownername, row.'Reponame, row.'UserID, accessToken);
                };
        } on fail error e {
            sql:Error? close = dbClient.close();
            io:println(e.message());
        }

    }
}

// time:Utc currentUtc = time:utcNow();
// time:Utc newTime = time:utcAddSeconds(currentUtc, 10);
// time:Civil time = time:utcToCivil(newTime);

// task:JobId result = check task:scheduleOneTimeJob(new CalculateMetricsPeriodically(), time);

