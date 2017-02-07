sub init()
  print "FindMedia.brs - [init]"
  m.port = createObject("roMessagePort")

  m.top.numRowsReceived = 0
  m.top.numBadRequests = 0
  m.top.contentSet = false

  ' Stores the content if not all requests are ready
  m.top.ContentCache = createObject("roSGNode", "ContentNode")

  ' setting callbacks for url request and response
  m.top.observeField("request", m.port)
  m.top.observeField("ContentCache", m.port)

  ' setting the task thread function
  m.top.functionName = "go"
  m.top.control = "RUN"
end sub

' Callback function for when content has finished parsing
sub updateContent()
  print "FindMedia.brs - [updateContent]"

  ' Received another row of content
  m.top.numRowsReceived++

  ' Return if the content is already set
  if m.top.contentSet return
  ' Set the UI if all content from all streams are ready
  ' Note: this technique is hindered by slowest request
  ' Need to think of a better asynchronous method here!
  if m.top.numRows = m.top.numRowsReceived
    parent = createObject("roSGNode", "ContentNode")
    for i = 0 to (m.top.numRowsReceived - 1)
      oldParent = m.top.contentCache.getField(i.toStr())
      if oldParent <> invalid
        for j = 0 to (oldParent.getChildCount() - 1)
          oldParent.getChild(0).reparent(parent,true)
        end for
      end if
    end for
    print "All content has finished loading"
    m.top.contentSet = true
    m.top.content = parent
  else
    print "Not all content has finished loading yet"
  end if
end sub

' go(): The "Task" function.
'   Has an event loop which calls the appropriate functions for
'   handling requests made by the HeroScreen and responses when requests are finished
' variables:
'   m.jobsById: AA storing HTTP transactions where:
'			key: id of HTTP request
'  		val: an AA containing:
'       - key: context
'         val: a node containing request info
'       - key: xfer
'         val: the roUrlTransfer object
sub go()
  print "MediaFinder.brs - [go]"

  ' Holds requests by id
  m.jobsById = {}

	' UriFetcher event loop
  while true
    msg = wait(0, m.port)
    mt = type(msg)
    print "Received event type '"; mt; "'"
	
    ' If a request was made
    if mt = "roSGNodeEvent"
      if msg.getField()="request"
        if addRequest(msg.getData()) <> true then print "Invalid request"
      else if msg.getField()="ContentCache"
        updateContent()
      else
        print "Error: unrecognized field '"; msg.getField() ; "'"
      end if
    ' If a response was received
    else if mt="roUrlEvent"
      processResponse(msg)
    ' Handle unexpected cases
    else
	   print "Error: unrecognized event type '"; mt ; "'"
    end if
  end while
end sub

' addRequest():
'   Makes the HTTP request
' parameters:
'		request: a node containing the request params/context.
' variables:
'   m.jobsById: used to store a history of HTTP requests
' return value:
'   True if request succeeds
' 	False if invalid request
function addRequest(request as Object) as Boolean
  print "MediaFinder.brs - [addRequest]"

  if type(request) = "roAssociativeArray"
    context = request.context
    'parser = request.parser
    'if type(parser) = "roString"
    '  if m.Parser = invalid
    '    m.Parser = createObject("roSGNode", parser)
    '    m.Parser.observeField("parsedContent", m.port)
    '  else
    '    print "Parser already created"
    '  end if
    'else
    '  print "Error: Incorrect type for Parser: " ; type(parser)
    '  return false
    'end if
  	if type(context) = "roSGNode"
      parameters = context.parameters
      if type(parameters)="roAssociativeArray"
      	uri = parameters.uri
        if type(uri) = "roString"
          urlXfer = createObject("roUrlTransfer")
		  urlXfer.EnablePeerVerification(false)
          urlXfer.setUrl(uri)
          urlXfer.setPort(m.port)
          ' should transfer more stuff from parameters to urlXfer
          idKey = stri(urlXfer.getIdentity()).trim()
          ' AsyncGetToString returns false if the request couldn't be issued
          ok = urlXfer.AsyncGetToString()
          if ok then
            m.jobsById[idKey] = {
              context: request,
              xfer: urlXfer
            }
          else
            print "Error: request couldn't be issued"
          end if
  		    print "Initiating transfer '"; idkey; "' for URI '"; uri; "'"; " succeeded: "; ok
        else
          print "Error: invalid uri: "; uri
          m.top.numBadRequests++
  		end if
      else
        print "Error: parameters is the wrong type: " + type(parameters)
        return false
      end if
  	else
      print "Error: context is the wrong type: " + type(context)
  		return false
  	end if
  else
    print "Error: request is the wrong type: " + type(request)
    return false
  end if
  return true
end function

' processResponse():
'   Processes the HTTP response.
'   Sets the node's response field with the response info.
' parameters:
' 	msg: a roUrlEvent (https://sdkdocs.roku.com/display/sdkdoc/roUrlEvent)
sub processResponse(msg as Object)
  print "FindMedia.brs - [processResponse]"
  idKey = stri(msg.GetSourceIdentity()).trim()
  job = m.jobsById[idKey]
  if job <> invalid
    context = job.context
    parameters = context.context.parameters
    jobnum = job.context.context.num
    uri = parameters.uri
    print "Response for transfer '"; idkey; "' for URI '"; uri; "'"
    result = {
      code:    msg.GetResponseCode(),
      headers: msg.GetResponseHeaders(),
      content: msg.GetString(),
      num:     jobnum
    }
    ' could handle various error codes, retry, etc. here
    m.jobsById.delete(idKey)
    job.context.context.response = result
    if msg.GetResponseCode() = 200
	  xml = CreateObject("roXMLElement")
	  xml.Parse(result.content)
      if not xml.Parse(result.content) return
      if xml <> invalid then
        xml = xml.getchildelements()
        responsearray = xml.getchildelements()
      end if
	  
      result = []
      for each xmlitem in responsearray
        itemaa = xmlitem.getchildelements()
		print xmlitem.getname(); " - "; xmlitem.gettext()
		if xmlitem.getname() = "location"
		  m.top.urlstring=xmlitem.gettext()
		end if
	  end for
    else
      print "Error: status code was: " + (msg.GetResponseCode()).toStr()
	  print "FULL MSG: " + (msg.GetString()).toStr()
      m.top.numBadRequests++
      m.top.numRowsReceived++
    end if
  else
    print "Error: event for unknown job "; idkey
  end if
end sub
