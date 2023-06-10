import ballerina/sql;

type AletLimitsInDB record {
    string 'userId;
    float 'WontFixIssuesRatio;
    int 'WeeklyCommitCount;
    int 'MeanPullRequestResponseTime;
    float 'MeanLeadTimeForPulls;
    float 'ResponseTimeforIssue;
};

public function setUserAlertLimits(string userId, float wontFixIssuesRatio, int weeklyCommitCount, int meanPullRequestResponseTime, float meanLeadTimeForPulls, float responseTimeforIssue) returns sql:ExecutionResult|error {
    do {
        sql:ExecutionResult|sql:Error result = check dbClient->execute(`
	            UPDATE AlertLimits
                SET WontFixIssuesRatio= ${wontFixIssuesRatio},WeeklyCommitCount=${weeklyCommitCount},MeanPullRequestResponseTime=${meanPullRequestResponseTime},MeanLeadTimeForPulls=${meanLeadTimeForPulls},ResponseTimeforIssue=${responseTimeforIssue} WHERE UserID=${userId}`);
        return result;
    } on fail var err {
        return err;
    }

};

public function getUserAlertLimits(string userId) returns AletLimitsInDB[]|error {
    do {

        stream<AletLimitsInDB, sql:Error?> resultStream = dbClient->query(`SELECT * FROM AlertLimits WHERE UserID = ${userId}`);
        return from AletLimitsInDB limits in resultStream
            select limits;
    } on fail error e {
        return e;
    }

};
