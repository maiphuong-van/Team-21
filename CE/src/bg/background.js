// Checks the URL if it's 'youtube.com/watch' (a youtube video page), shows page action icon if true
chrome.tabs.onUpdated.addListener(function(tabId, changeInfo, tab)
{
	if(tab.url.indexOf('youtube.com/watch') > -1)
	{
		chrome.pageAction.show(tabId);
	}
});


