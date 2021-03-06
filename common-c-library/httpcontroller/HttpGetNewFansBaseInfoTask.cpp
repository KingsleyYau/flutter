/*
 * HttpGetNewFansBaseInfoTask.cpp
 *
 *  Created on: 2017-8-30
 *      Author: Alex
 *        desc: 3.12.获取指定观众信息
 */

#include "HttpGetNewFansBaseInfoTask.h"

HttpGetNewFansBaseInfoTask::HttpGetNewFansBaseInfoTask() {
	// TODO Auto-generated constructor stub
	mPath = LIVEROOM_GETNEWFANSBASEINFO;
    mUserId = "";
}

HttpGetNewFansBaseInfoTask::~HttpGetNewFansBaseInfoTask() {
	// TODO Auto-generated destructor stub
}

void HttpGetNewFansBaseInfoTask::SetCallback(IRequestGetNewFansBaseInfoCallback* callback) {
	mpCallback = callback;
}

void HttpGetNewFansBaseInfoTask::SetParam(
                                   const string& userId
                                          ) {

//	char temp[16];
	mHttpEntiy.Reset();
	mHttpEntiy.SetSaveCookie(true);
    
    if( userId.length() > 0 ) {
        mHttpEntiy.AddContent(LIVEROOM_GETNEWFANSBASEINFO_USERID, userId.c_str());
        mUserId = userId;
    }

    FileLog(LIVESHOW_HTTP_LOG,
            "HttpGetNewFansBaseInfoTask::SetParam( "
            "task : %p, "
            ")",
            this
            );
}

const string& HttpGetNewFansBaseInfoTask::GetUserId() {
    return mUserId;
}

bool HttpGetNewFansBaseInfoTask::ParseData(const string& url, bool bFlag, const char* buf, int size) {
    FileLog(LIVESHOW_HTTP_LOG,
            "HttpGetNewFansBaseInfoTask::ParseData( "
            "task : %p, "
            "url : %s, "
            "bFlag : %s "
            ")",
            this,
            url.c_str(),
            bFlag?"true":"false"
            );
    
    int errnum = LOCAL_LIVE_ERROR_CODE_FAIL;
    string errmsg = "";
    bool bParse = false;
    HttpLiveFansInfoItem item;
    
    if ( bFlag ) {
        // 公共解析
        Json::Value dataJson;
        if( ParseLiveCommon(buf, size, errnum, errmsg, &dataJson) ) {
            item.Parse(dataJson);
        }
        
        bParse = (errnum == LOCAL_LIVE_ERROR_CODE_SUCCESS ? true : false);
        
        
    } else {
        // 超时
        errnum = HTTP_LCC_ERR_CONNECTFAIL;
        errmsg = LOCAL_ERROR_CODE_TIMEOUT_DESC;
    }
    
    item.userId = mUserId;

    if( mpCallback != NULL ) {
        mpCallback->OnGetNewFansBaseInfo(this, bParse, errnum, errmsg, item);
    }
    
    return bParse;
}

