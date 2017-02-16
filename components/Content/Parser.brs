' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********

sub init()
  print "Parser.brs - [init]"
end sub

' Parses the response string as XML
' The parsing logic will be different for different RSS feeds
sub parseResponse()
  print "Parser.brs - [parseResponse]"
  str = m.top.response.content
  num = m.top.response.num

  if str = invalid return
  xml = CreateObject("roXMLElement")
  ' Return invalid if string can't be parsed
  if not xml.Parse(str) return

  if xml <> invalid then
    xml = xml.getchildelements()
    responsearray = xml.getchildelements()
  end if

  result = []
  m.type="invalid"
  for each xmlitem in responsearray
    if xmlitem.getname() = "item"
      m.type="itemlist"
      ' All things related to one item (title, link, description, media:content, etc.)
      itemaa = xmlitem.getchildelements()
      if itemaa <> invalid
        item = {}
        ' Get all <item> attributes
        for each xmlitem in itemaa
          item[xmlitem.getname()] = xmlitem.gettext()
          if xmlitem.getname() = "media:content"
            item.stream = {url : xmlitem.url}
            item.url = xmlitem.getattributes().url
            item.streamformat = "mp4"

            mediacontent = xmlitem.getchildelements()
            for each mediacontentitem in mediacontent
              if mediacontentitem.getname() = "media:thumbnail"
                item.hdposterurl = mediacontentitem.getattributes().url
                item.uri = mediacontentitem.getattributes().url
              end if
              if mediacontentitem.getname() = "media:backdrop"
                item.hdbackgroundimageurl = mediacontentitem.getattributes().url
              end if
            end for
          end if
        end for
      
        if item.title = "Unauthorized Device" 
            sec = CreateObject("roRegistrySection", "Settings")
            sec.Delete("registration")
            sec.Flush()   
        end if
        result.push(item)
      end if
    
    else if xmlitem.getname() = "urlfound"
      m.type="mp4find"
      itemaa = xmlitem.getchildelements()
      if itemaa <> invalid
        item = {}
        ' Get all <item> attributes
        for each xmlitem in itemaa
          item[xmlitem.getname()] = xmlitem.gettext()
          print xmlitem.getname(); " - "; xmlitem.gettext()
        end for
        result.push(item)
      end if
    end if
  end for



  list = [
    {
        Title:"Page 1 (newest)"
        ContentList : result
    }
    {
        Title:"Page 2"
        ContentList : result
    }
    {
        Title:"Page 3"
        ContentList : result
    }
    {
        Title:"Page 4"
        ContentList : result
    }
    {
        Title:"Page 5"
        ContentList : result
    }
    {
        Title:"Page 6"
        ContentList : result
    }
  ]

  contentAA = {}
  
  content = createRow(list, num)

  'Add the newly parsed content row/grid to the cache until everything is ready
  if content <> invalid
    contentAA[num.toStr()] = content
    if m.UriHandler = invalid then m.UriHandler = m.top.getParent()
    m.UriHandler.contentCache.addFields(contentAA)
  else
    print "Error: content was invalid"
  end if
end sub

'Create a row of content
function createRow(list as object, num as Integer)
  print "Parser.brs - [createRow]"
  Parent = createObject("RoSGNode", "ContentNode")
  row = createObject("RoSGNode", "ContentNode")
  row.Title = list[num].Title
  for each itemAA in list[num].ContentList
    item = createObject("RoSGNode","ContentNode")
    AddAndSetFields(item, itemAA)
    row.appendChild(item)
  end for
  Parent.appendChild(row)
  return Parent
end function
