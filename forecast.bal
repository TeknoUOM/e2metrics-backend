import ballerina/sql;
import ballerinax/mysql;
import ballerina/time;
import ballerina/regex;

function getForecast(string UserId, string ownername, string reponame) returns json[]|error {

    float AVGIssuesFixingFrequency = 0;
    float AVGBugFixRatio = 0;
    int AVGCommitCount = 0;
    int AVGtotalNumberOfLines = 0;
    float AVGMeanLeadFixTime = 0;
    int AVGPullRequestFrequency = 0;
    int AVGOpenedIssuesCount = 0;
    int AVGAllIssuesCount = 0;
    float AVGWontFixIssuesRatio = 0;
    int AVGMeanPullRequestResponseTime = 0;
    int AVGPullRequestCount = 0;
    int AVGWeeklyCommitCount = 0;
    float AVGMeanLeadTimeForPulls = 0;
    float AVGResponseTimeforIssue = 0;
    float total_XY_IssuesFixingFrequency = 0;
    float total_XY_BugFixRatio = 0;
    int total_XY_CommitCount = 0;
    int total_XY_totalNumberOfLines = 0;
    float total_XY_MeanLeadFixTime = 0;
    int total_XY_PullRequestFrequency = 0;
    int total_XY_OpenedIssuesCount = 0;
    int total_XY_AllIssuesCount = 0;
    float total_XY_WontFixIssuesRatio = 0;
    int total_XY_MeanPullRequestResponseTime = 0;
    int total_XY_PullRequestCount = 0;
    float total_XY_MeanLeadTimeForPulls = 0;
    float total_XY_ResponseTimeforIssue = 0;
    int total_XY_WeeklyCommitCount = 0;
    float AVGx = 0;
    float totalSqareX = 0;
    float a_IssuesFixingFrequency = 0;
    float a_BugFixRatio = 0;
    float a_CommitCount = 0;
    float a_totalNumberOfLines = 0;
    float a_MeanLeadFixTime = 0;
    float a_PullRequestFrequency = 0;
    float a_OpenedIssuesCount = 0;
    float a_AllIssuesCount = 0;
    float a_WontFixIssuesRatio = 0;
    float a_MeanPullRequestResponseTime = 0;
    float a_PullRequestCount = 0;
    float a_MeanLeadTimeForPulls = 0;
    float a_ResponseTimeforIssue = 0;
    float a_WeeklyCommitCount = 0;

    float b_IssuesFixingFrequency = 0;
    float b_BugFixRatio = 0;
    float b_CommitCount = 0;
    float b_totalNumberOfLines = 0;
    float b_MeanLeadFixTime = 0;
    float b_PullRequestFrequency = 0;
    float b_OpenedIssuesCount = 0;
    float b_AllIssuesCount = 0;
    float b_WontFixIssuesRatio = 0;
    float b_MeanPullRequestResponseTime = 0;
    float b_PullRequestCount = 0;
    float b_MeanLeadTimeForPulls = 0;
    float b_ResponseTimeforIssue = 0;
    float b_WeeklyCommitCount = 0;

    float[] IssuesFixingFrequency = [];
    float[] BugFixRatio = [];
    float[] CommitCount = [];
    float[] totalNumberOfLines = [];
    float[] MeanLeadFixTime = [];
    float[] PullRequestFrequency = [];
    float[] OpenedIssuesCount = [];
    float[] AllIssuesCount = [];
    float[] WontFixIssuesRatio = [];
    float[] MeanPullRequestResponseTime = [];
    float[] PullRequestCount = [];
    float[] MeanLeadTimeForPulls = [];
    float[] ResponseTimeforIssue = [];
    float[] WeeklyCommitCount = [];
    json[] returnData = [];

    int count = 0;

    sql:ParameterizedQuery query1 = `SELECT * FROM E2Metrices.DailyPerfomance WHERE UserId=${UserId} AND reponame=${reponame} AND ownername=${ownername}`;
    mysql:Client dbClient = check new (hostname, username, password, "E2Metrices", port);

    stream<Perfomance, sql:Error?> queryResult = dbClient->query(query1);
    check from Perfomance performance in queryResult

        do {
            count = count + 1;
            AVGIssuesFixingFrequency += performance.IssuesFixingFrequency;
            AVGBugFixRatio = AVGBugFixRatio + performance.BugFixRatio;
            AVGCommitCount = AVGCommitCount + performance.CommitCount;
            AVGtotalNumberOfLines = AVGtotalNumberOfLines + performance.totalNumberOfLines;
            AVGMeanLeadFixTime = AVGMeanLeadFixTime + performance.MeanLeadFixTime;
            AVGPullRequestFrequency = AVGPullRequestFrequency + performance.PullRequestFrequency;
            AVGOpenedIssuesCount = AVGOpenedIssuesCount + performance.OpenedIssuesCount;
            AVGAllIssuesCount = AVGAllIssuesCount + performance.AllIssuesCount;
            AVGWontFixIssuesRatio = AVGWontFixIssuesRatio + performance.WontFixIssuesRatio;
            AVGMeanPullRequestResponseTime = AVGMeanPullRequestResponseTime + performance.MeanPullRequestResponseTime;
            AVGPullRequestCount = AVGPullRequestCount + performance.PullRequestCount;
            AVGMeanLeadTimeForPulls = AVGMeanLeadTimeForPulls + performance.MeanLeadTimeForPulls;
            AVGResponseTimeforIssue = AVGResponseTimeforIssue + performance.ResponseTimeforIssue;
            AVGWeeklyCommitCount = AVGWeeklyCommitCount + performance.WeeklyCommitCount;
            total_XY_IssuesFixingFrequency = total_XY_IssuesFixingFrequency + (performance.IssuesFixingFrequency * count);
            total_XY_BugFixRatio = total_XY_BugFixRatio + (performance.BugFixRatio * count);
            total_XY_CommitCount = total_XY_CommitCount + (performance.CommitCount * count);
            total_XY_totalNumberOfLines = total_XY_totalNumberOfLines + (performance.totalNumberOfLines * count);
            total_XY_MeanLeadFixTime = total_XY_MeanLeadFixTime + (performance.MeanLeadFixTime * count);
            total_XY_PullRequestFrequency = total_XY_PullRequestFrequency + (performance.PullRequestFrequency * count);
            total_XY_OpenedIssuesCount = total_XY_OpenedIssuesCount + (performance.OpenedIssuesCount * count);
            total_XY_AllIssuesCount = total_XY_AllIssuesCount + (performance.AllIssuesCount * count);
            total_XY_WontFixIssuesRatio = total_XY_WontFixIssuesRatio + (performance.WontFixIssuesRatio * count);
            total_XY_MeanPullRequestResponseTime = total_XY_MeanPullRequestResponseTime + (performance.MeanPullRequestResponseTime * count);
            total_XY_PullRequestCount = total_XY_PullRequestCount + (performance.PullRequestCount * count);
            total_XY_MeanLeadTimeForPulls = total_XY_MeanLeadTimeForPulls + (performance.MeanLeadTimeForPulls * count);
            total_XY_ResponseTimeforIssue = total_XY_ResponseTimeforIssue + (performance.ResponseTimeforIssue * count);
            total_XY_WeeklyCommitCount = total_XY_WeeklyCommitCount + (performance.WeeklyCommitCount * count);

        };

    if (count == 0) {
        return error("no daily performance yet", message = "no perfomance for repo", code = 400);
    }
    AVGIssuesFixingFrequency = AVGIssuesFixingFrequency / count;
    AVGBugFixRatio = AVGBugFixRatio / count;
    AVGCommitCount = AVGCommitCount / count;
    AVGtotalNumberOfLines = AVGtotalNumberOfLines / count;
    AVGMeanLeadFixTime = AVGMeanLeadFixTime / count;
    AVGPullRequestFrequency = AVGPullRequestFrequency / count;
    AVGOpenedIssuesCount = AVGOpenedIssuesCount / count;
    AVGAllIssuesCount = AVGAllIssuesCount / count;
    AVGWontFixIssuesRatio = AVGWontFixIssuesRatio / count;
    AVGMeanPullRequestResponseTime = AVGMeanPullRequestResponseTime / count;
    AVGPullRequestCount = AVGPullRequestCount / count;
    AVGMeanLeadTimeForPulls = AVGMeanLeadTimeForPulls / count;
    AVGResponseTimeforIssue = AVGResponseTimeforIssue / count;
    AVGWeeklyCommitCount = AVGWeeklyCommitCount / count;

    foreach int i in 1 ... count {
        AVGx = AVGx + <float>i;

    }
    AVGx = AVGx / count;

    foreach int i in 1 ... count {
        totalSqareX = totalSqareX + <float>(i * i);

    }

    b_IssuesFixingFrequency = (total_XY_IssuesFixingFrequency - (count * AVGx * AVGIssuesFixingFrequency)) / (totalSqareX - (count * AVGx * AVGx));
    b_BugFixRatio = (total_XY_BugFixRatio - (count * AVGx * AVGBugFixRatio)) / (totalSqareX - (count * AVGx * AVGx));
    b_CommitCount = (<float>total_XY_CommitCount - (count * AVGx * AVGCommitCount)) / (totalSqareX - (count * AVGx * AVGx));
    b_totalNumberOfLines = (<float>total_XY_totalNumberOfLines - (count * AVGx * AVGtotalNumberOfLines)) / (totalSqareX - (count * AVGx * AVGx));
    b_MeanLeadFixTime = (total_XY_MeanLeadFixTime - (count * AVGx * AVGMeanLeadFixTime)) / (totalSqareX - (count * AVGx * AVGx));
    b_PullRequestFrequency = (<float>total_XY_PullRequestFrequency - (count * AVGx * AVGPullRequestFrequency)) / (totalSqareX - (count * AVGx * AVGx));
    b_OpenedIssuesCount = (<float>total_XY_OpenedIssuesCount - (count * AVGx * AVGOpenedIssuesCount)) / (totalSqareX - (count * AVGx * AVGx));
    b_AllIssuesCount = (<float>total_XY_AllIssuesCount - (count * AVGx * AVGAllIssuesCount)) / (totalSqareX - (count * AVGx * AVGx));
    b_WontFixIssuesRatio = (total_XY_WontFixIssuesRatio - (count * AVGx * AVGWontFixIssuesRatio)) / (totalSqareX - (count * AVGx * AVGx));
    b_MeanPullRequestResponseTime = (<float>total_XY_MeanPullRequestResponseTime - (count * AVGx * AVGMeanPullRequestResponseTime)) / (totalSqareX - (count * AVGx * AVGx));
    b_PullRequestCount = (<float>total_XY_PullRequestCount - (count * AVGx * AVGPullRequestCount)) / (totalSqareX - (count * AVGx * AVGx));
    b_MeanLeadTimeForPulls = (total_XY_MeanLeadTimeForPulls - (count * AVGx * AVGMeanLeadTimeForPulls)) / (totalSqareX - (count * AVGx * AVGx));
    b_ResponseTimeforIssue = (total_XY_ResponseTimeforIssue - (count * AVGx * AVGResponseTimeforIssue)) / (totalSqareX - (count * AVGx * AVGx));
    b_WeeklyCommitCount = (<float>total_XY_WeeklyCommitCount - (count * AVGx * AVGWeeklyCommitCount)) / (totalSqareX - (count * AVGx * AVGx));

    a_IssuesFixingFrequency = AVGIssuesFixingFrequency - (b_IssuesFixingFrequency * AVGx);
    a_BugFixRatio = AVGBugFixRatio - (b_BugFixRatio * AVGx);
    a_CommitCount = <float>AVGCommitCount - (b_CommitCount * AVGx);
    a_totalNumberOfLines = <float>AVGtotalNumberOfLines - (b_totalNumberOfLines * AVGx);
    a_MeanLeadFixTime = AVGMeanLeadFixTime - (b_MeanLeadFixTime * AVGx);
    a_PullRequestFrequency = <float>AVGPullRequestFrequency - (b_PullRequestFrequency * AVGx);
    a_OpenedIssuesCount = <float>AVGOpenedIssuesCount - (b_OpenedIssuesCount * AVGx);
    a_AllIssuesCount = <float>AVGAllIssuesCount - (b_AllIssuesCount * AVGx);
    a_WontFixIssuesRatio = AVGWontFixIssuesRatio - (b_WontFixIssuesRatio * AVGx);
    a_MeanPullRequestResponseTime = <float>AVGMeanPullRequestResponseTime - (b_MeanPullRequestResponseTime * AVGx);
    a_PullRequestCount = <float>AVGPullRequestCount - (b_PullRequestCount * AVGx);
    a_MeanLeadTimeForPulls = AVGMeanLeadTimeForPulls - (b_MeanLeadTimeForPulls * AVGx);
    a_ResponseTimeforIssue = AVGResponseTimeforIssue - (b_ResponseTimeforIssue * AVGx);
    a_WeeklyCommitCount = <float>AVGWeeklyCommitCount - (b_WeeklyCommitCount * AVGx);
    int j = 0;
    time:Utc currentUtc = time:utcNow();
    time:Civil time = time:utcToCivil(currentUtc);
    time.utcOffset = {hours: 5, minutes: 30, seconds: 0d};
    string date;

    foreach int i in count ... count + 30 {

        IssuesFixingFrequency[j] = (a_IssuesFixingFrequency + (b_IssuesFixingFrequency * count));
        BugFixRatio[j] = a_BugFixRatio + (b_BugFixRatio * count);
        CommitCount[j] = a_CommitCount + (b_CommitCount * count);
        totalNumberOfLines[j] = a_totalNumberOfLines + (b_totalNumberOfLines * count);
        MeanLeadFixTime[j] = a_MeanLeadFixTime + (b_MeanLeadFixTime * count);
        PullRequestFrequency[j] = a_PullRequestFrequency + (b_PullRequestFrequency * count);
        OpenedIssuesCount[j] = a_OpenedIssuesCount + (b_OpenedIssuesCount * count);
        AllIssuesCount[j] = a_AllIssuesCount + (b_AllIssuesCount * count);
        WontFixIssuesRatio[j] = a_WontFixIssuesRatio + (b_WontFixIssuesRatio * count);
        MeanPullRequestResponseTime[j] = a_MeanPullRequestResponseTime + (b_MeanPullRequestResponseTime * count);
        PullRequestCount[j] = a_PullRequestCount + (b_PullRequestCount * count);
        MeanLeadTimeForPulls[j] = a_MeanLeadTimeForPulls + (b_MeanLeadTimeForPulls * count);
        ResponseTimeforIssue[j] = a_ResponseTimeforIssue + (b_ResponseTimeforIssue * count);
        WeeklyCommitCount[j] = a_WeeklyCommitCount + (b_WeeklyCommitCount * count);

        string dateTime = time:utcToString(currentUtc);

        do {
            string[] dateAndTimeArray = regex:split(dateTime, "T");
            date = dateAndTimeArray[0];
        }

        returnData[j] = {Date: date, Ownername: ownername, Reponame: reponame, UserId: UserId, IssuesFixingFrequency: IssuesFixingFrequency[j], BugFixRatio: BugFixRatio[j], CommitCount: CommitCount[j], totalNumberOfLines: totalNumberOfLines[j], MeanLeadFixTime: MeanLeadFixTime[j], PullRequestFrequency: PullRequestFrequency[j], OpenedIssuesCount: OpenedIssuesCount[j], AllIssuesCount: AllIssuesCount[j], WontFixIssuesRatio: WontFixIssuesRatio[j], MeanPullRequestResponseTime: MeanPullRequestResponseTime[j], PullRequestCount: PullRequestCount[j], MeanLeadTimeForPulls: MeanLeadTimeForPulls[j], ResponseTimeforIssue: ResponseTimeforIssue[j], WeeklyCommitCount: WeeklyCommitCount[j]};
        j = j + 1;
        time:Utc newTime = time:utcAddSeconds(currentUtc, 86400);
        currentUtc = newTime;
    }

    return (returnData);
}
