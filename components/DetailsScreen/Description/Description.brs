' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********

 'setting top interfaces
Sub Init()
  print "Description.brs - [Init]"
  m.top.Title             = m.top.findNode("Title")
  m.top.Description       = m.top.findNode("Description")
  m.top.Genre             = m.top.findNode("Genre")
  m.top.Runtime           = m.top.findNode("Runtime")
  m.top.ReleaseDate       = m.top.findNode("ReleaseDate")
  m.top.Quality           = m.top.findNode("Quality")
  m.top.Budget            = m.top.findNode("Budget")
  m.top.Revenue           = m.top.findNode("Revenue")
End Sub

' Content change handler
' All fields population
Sub OnContentChanged()
  print "Description.brs - [OnContentChanged]"
  item = m.top.content

  title = item.title.toStr()
  if title <> invalid then
    m.top.Title.text = title.toStr()
  end if

  value = item.description
  if value <> invalid then
    if value.toStr() <> "" then
      m.top.Description.text = value.toStr()
    else
      m.top.Description.text = "No description"
    end if
  end if

  value = item.longQuality
  if value <> invalid then
    if value <> ""
      m.top.Quality.text = "Quality: " + value.toStr()
    else
      m.top.Quality.text = "Quality: Unknown"
    end if
  end if

  value = item.Genres
  if value <> invalid then
    if value <> ""
      m.top.Genre.text = "Genre: " + value.toStr()
    else
      m.top.Genre.text = "Genre: Unknown"
    end if
  end if

  value = item.Runtime
  if value <> invalid then
    if value <> ""
      m.top.Runtime.text = "Runtime: " + value.toStr()
    else
      m.top.Runtime.text = "Runtime: Unknown"
    end if
  end if

  value = item.ReleaseDate
  if value <> invalid then
    if value <> ""
      m.top.ReleaseDate.text = "Release Date: " + value.toStr()
    else
      m.top.ReleaseDate.text = "No Release Date"
    end if
  end if

  value = item.Budget
  if value <> invalid then
    if value <> ""
      m.top.Budget.text = "Budget: " + value.toStr()
    end if
  end if

  value = item.Revenue
  if value <> invalid then
    if value <> ""
      m.top.Revenue.text = "Revenue: " + value.toStr()
    end if
  end if
End Sub

