import React, { useState, useEffect, useRef } from 'react';
import { makeStyles } from "@mui/styles"
import { TextField, Button, Typography, InputAdornment, Avatar } from "@mui/material"
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome"
import Nui from "../../util/Nui"
import { useSelector } from "react-redux"

const useStyles = (themeColor) =>
  makeStyles((theme) => ({
    wrapper: {
      position: "relative",
      height: "100%",
      background: theme.palette.secondary.main,
      overflow: "auto",
      padding: "20px",
    },
    title: {
      fontSize: "28px",
      textAlign: "center",
      marginBottom: "15px",
      color: themeColor,
      fontWeight: "bold",
      textShadow: "0 0 5px rgba(61, 61, 255, 0.3)",
    },
    subtitle: {
      fontSize: "18px",
      textAlign: "center",
      marginBottom: "30px",
      color: "#fff",
    },
    chatWrapper: {
      position: "relative",
      width: "60%",
      height: "45vh",
      margin: "0 auto",
      display: "flex",
      flexDirection: "column",
      background: "rgba(30, 30, 30, 0.7)",
      borderRadius: "15px",
      boxShadow: `0 0 15px ${themeColor}`,
      padding: "20px",
    },
    chatTexts: {
      flex: 1,
      overflow: "hidden",
      overflowY: "auto",
      display: "flex",
      flexDirection: "column-reverse",
      marginBottom: "15px",
      padding: "10px",
    },
    chatText: {
      width: "100%",
      display: "flex",
      flexDirection: "column",
      alignItems: "flex-start",
      marginBottom: "15px",
    },
    textOut: {
      alignItems: "flex-end",
    },
    inner: {
      width: "max-content",
      maxWidth: "80%",
      borderRadius: "15px",
      padding: "12px",
      background: "#37474f",
      boxShadow: "0 2px 5px rgba(0, 0, 0, 0.2)",
    },
    innerOut: {
      background: themeColor,
      boxShadow: `0 2px 5px rgba(0, 0, 0, 0.3)`,
    },
    messageText: {
      fontSize: "16px",
      margin: "0",
      overflowWrap: "anywhere",
      color: "white",
    },
    timestamp: {
      display: "flex",
      marginTop: "5px",
      padding: "0 5px",
    },
    timestampText: {
      color: "#9e9e9e",
      fontSize: "12px",
      margin: 0,
    },
    imageContainer: {
      maxWidth: "80%",
      margin: "10px 0",
    },
    image: {
      maxWidth: "100%",
      borderRadius: "10px",
      boxShadow: "0 2px 5px rgba(0, 0, 0, 0.2)",
    },
    inputContainer: {
      display: "flex",
      alignItems: "center",
    },
    messageInput: {
      flex: 1,
      "& .MuiOutlinedInput-root": {
        color: "white",
        "& fieldset": {
          borderColor: "rgba(255, 255, 255, 0.3)",
        },
        "&:hover fieldset": {
          borderColor: themeColor,
        },
        "&.Mui-focused fieldset": {
          borderColor: themeColor,
        },
      },
    },
    sendButton: {
      background: themeColor,
      color: "white",
      marginLeft: "10px",
      "&:hover": {
        background: "#c010a8",
      },
    },
    emptyMsg: {
      width: "100%",
      textAlign: "center",
      fontSize: "24px",
      fontWeight: "bold",
      marginTop: "22%",
      color: themeColor,
    },
    senderInfo: {
      display: "flex",
      alignItems: "center",
      marginBottom: "5px",
    },
    avatar: {
      width: 30,
      height: 30,
      marginRight: "10px",
      backgroundColor: themeColor,
    },
    senderName: {
      fontSize: "14px",
      fontWeight: "bold",
      color: "#ccc",
    },
  }))

export default function Chat({ groupData, themeColor = "#e412ca" }) {
  const classes = useStyles(themeColor)()
  const [chatMessages, setChatMessages] = useState([])
  const [messageText, setMessageText] = useState("")
  const playerData = useSelector((state) => state.data.data.player)
  const chatEndRef = useRef(null)

  useEffect(() => {
    if (groupData?.Id && groupData.TotalSprays >= 16) {
      fetchMessages()
    }
  }, [groupData])

  const fetchMessages = async () => {
    try {
      const response = await (await Nui.send("Unknown/GetMessages")).json()
      setChatMessages(response || [])
    } catch (error) {
      console.error("Error fetching messages:", error)
      setChatMessages([])
    }
  }

  const isMessageSender = (message) => {
    return message.Sender === playerData.Cid
  }

  const extractImageUrls = (text) => {
    // This is a simplified version - in a real app you'd need proper URL extraction
    const urlRegex = /(https?:\/\/[^\s]+)/g
    const urls = text.match(urlRegex) || []
    const message = text.replace(urlRegex, "").trim()
    return [urls, message]
  }

  const handleSendMessage = async (e) => {
    e.preventDefault()
    if (messageText.length <= 0) return

    const [attachments, message] = extractImageUrls(messageText)

    try {
      await Nui.send("Unknown/SendMessage", { Attachments: attachments, Message: message })
      setMessageText("")
      // In a real app, the server would push new messages to all clients
      // For now, we'll just fetch messages again
      setTimeout(fetchMessages, 500)
    } catch (error) {
      console.error("Error sending message:", error)
    }
  }

  // Update the getTimeLabel and getLongTimeLabel functions to correctly display server time

  const getTimeLabel = (timestamp) => {
	// Return the timestamp as is, assuming it's in the correct format
	return timestamp.replace(" ", " - ");
  }  

  // Update the getLongTimeLabel function to use the same format
  const getLongTimeLabel = (timestamp) => {
    return getTimeLabel(timestamp)
  }

  // Helper function to get the day suffix (st, nd, rd, th)
  const getDaySuffix = (day) => {
    if (day > 3 && day < 21) return "th"
    switch (day % 10) {
      case 1:
        return "st"
      case 2:
        return "nd"
      case 3:
        return "rd"
      default:
        return "th"
    }
  }

  const getInitials = (name) => {
    if (!name) return "?"
    return name
      .split(" ")
      .map((n) => n[0])
      .join("")
      .toUpperCase()
  }

  if (!groupData?.Id) {
    return (
      <div className={classes.wrapper}>
        <Typography variant="h4" className={classes.title}>
          Gang Chat
        </Typography>
        <div className={classes.emptyMsg}>
          <FontAwesomeIcon icon={["fas", "comment-slash"]} size="2x" style={{ marginBottom: "15px" }} />
          <div>You must be in a gang to use chat</div>
        </div>
      </div>
    )
  }

  if (groupData.TotalSprays < 16) {
    return (
      <div className={classes.wrapper}>
        <Typography variant="h4" className={classes.title}>
          Gang Chat
        </Typography>
        <div className={classes.emptyMsg}>
          <FontAwesomeIcon icon={["fas", "lock"]} size="2x" style={{ marginBottom: "15px" }} />
          <div>Insufficient reputation to use chat</div>
          <div style={{ fontSize: "18px", marginTop: "10px", color: "#ccc" }}>
            You need at least level 3 (Established)
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className={classes.wrapper}>
      <Typography variant="h4" className={classes.title}>
        Gang Chat
      </Typography>

      <div className={classes.chatWrapper}>
        <div className={classes.chatTexts} ref={chatEndRef}>
          {chatMessages.map((message, index) => (
            <div key={index} className={`${classes.chatText} ${isMessageSender(message) ? classes.textOut : ""}`}>
              {!isMessageSender(message) && (
                <div className={classes.senderInfo}>
                  <Avatar className={classes.avatar}>{getInitials(message.SenderName)}</Avatar>
                  <span className={classes.senderName}>{message.SenderName}</span>
                </div>
              )}

              {message.Message && message.Message.length > 0 && (
                <div className={`${classes.inner} ${isMessageSender(message) ? classes.innerOut : ""}`}>
                  <p className={classes.messageText}>{message.Message}</p>
                </div>
              )}

              {message.Attachments && message.Attachments.length > 0 && (
                <div className={classes.imageContainer}>
                  {message.Attachments.map((url, i) => (
                    <img key={i} src={url || "/placeholder.svg"} alt="Attachment" className={classes.image} />
                  ))}
                </div>
              )}

              <div className={classes.timestamp} title={getLongTimeLabel(message.Timestamp)}>
                <p className={classes.timestampText}>{getTimeLabel(message.Timestamp)}</p>
              </div>
            </div>
          ))}
        </div>

        <form onSubmit={handleSendMessage} className={classes.inputContainer}>
          <TextField
            className={classes.messageInput}
            placeholder="Type a message..."
            value={messageText}
            onChange={(e) => setMessageText(e.target.value)}
            variant="outlined"
            fullWidth
            InputProps={{
              endAdornment: (
                <InputAdornment position="end">
                  <FontAwesomeIcon icon={["fas", "paperclip"]} style={{ color: "#ccc", cursor: "pointer" }} />
                </InputAdornment>
              ),
            }}
          />
          <Button type="submit" variant="contained" className={classes.sendButton}>
            <FontAwesomeIcon icon={["fas", "paper-plane"]} />
          </Button>
        </form>
      </div>
    </div>
  )
}
