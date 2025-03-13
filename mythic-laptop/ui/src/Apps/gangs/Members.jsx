import React, { useState } from 'react';
import { makeStyles } from "@mui/styles"
import {
  Button,
  Paper,
  Typography,
  TextField,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Divider,
} from "@mui/material"
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome"
import Nui from "../../util/Nui"
import { useAlert } from "../../hooks"

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
    addButton: {
      background: themeColor,
      color: "white",
      "&:hover": {
        background: "#c010a8",
      },
      margin: "0 auto 30px auto",
      display: "block",
      padding: "10px 20px",
    },
    memberGrid: {
      width: "100%",
      maxHeight: "60vh",
      padding: "0.2vh",
      margin: "0 auto",
      overflowY: "auto",
      display: "grid",
      gridTemplateColumns: "repeat(2, 1fr)",
      gridColumnGap: "20px",
      gridRowGap: "15px",
    },
    memberSlot: {
      display: "flex",
      justifyContent: "space-between",
      alignItems: "center",
      width: "100%",
      padding: "15px",
      background: "rgba(30, 30, 30, 0.7)",
      borderRadius: "10px",
      boxShadow: `0 0 5px ${themeColor}`,
      transition: "transform 0.3s ease",
      "&:hover": {
        transform: "scale(1.02)",
      },
    },
    leaderSlot: {
      background: "rgba(40, 40, 40, 0.8)",
      boxShadow: `0 0 10px ${themeColor}`,
    },
    memberName: {
      color: "white",
      fontSize: "18px",
      display: "flex",
      alignItems: "center",
    },
    memberIcon: {
      marginRight: "10px",
      color: themeColor,
    },
    leaderIcon: {
      marginRight: "10px",
      color: themeColor,
    },
    leaderNote: {
      color: "#a30000",
      opacity: 0.7,
      fontSize: "14px",
    },
    kickButton: {
      color: "#ff4d4d",
      fontSize: "16px",
      cursor: "pointer",
      display: "flex",
      alignItems: "center",
      "&:hover": {
        textDecoration: "underline",
      },
    },
    kickIcon: {
      marginRight: "5px",
    },
    dialogTitle: {
      color: themeColor,
      textAlign: "center",
    },
    dialogButton: {
      background: themeColor,
      color: "white",
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
  }))

export default function Members({ groupData, setGroupData, themeColor = "#e412ca" }) {
  const classes = useStyles(themeColor)()
  const alert = useAlert()

  const [addingMember, setAddingMember] = useState(false)
  const [memberCid, setMemberCid] = useState("")

  const handleAddMember = async () => {
    if (!memberCid.trim()) {
      alert("Please enter a valid State ID")
      return
    }

    try {
      await Nui.send("Unknown/AddMember", { Cid: memberCid })
      setAddingMember(false)
      setMemberCid("")
      alert("Member added successfully")
      // Refresh group data would happen here in a real implementation
    } catch (error) {
      console.error("Error adding member:", error)
      alert("Failed to add member")
    }
  }

  const handleKickMember = async (cid, index) => {
    try {
      await Nui.send("Unknown/KickMember", { Cid: cid })

      // Update local state to reflect the change
      const updatedMembers = [...groupData.Members]
      updatedMembers.splice(index, 1)
      setGroupData({
        ...groupData,
        Members: updatedMembers,
      })

      alert("Member kicked successfully")
    } catch (error) {
      console.error("Error kicking member:", error)
      alert("Failed to kick member")
    }
  }

  if (!groupData?.Id) {
    return (
      <div className={classes.wrapper}>
        <Typography variant="h4" className={classes.title}>
          Current Members (0)
        </Typography>
        <div className={classes.emptyMsg}>
          <FontAwesomeIcon icon={["fas", "users-slash"]} size="2x" style={{ marginBottom: "15px" }} />
          <div>You must be in a gang to manage members</div>
        </div>
      </div>
    )
  }

  return (
    <div className={classes.wrapper}>
      <Typography variant="h4" className={classes.title}>
        Current Members ({(groupData.Members?.length || 0) + 1})
      </Typography>

      <Button
        variant="contained"
        className={classes.addButton}
        onClick={() => setAddingMember(true)}
        startIcon={<FontAwesomeIcon icon={["fas", "user-plus"]} />}
      >
        Add Member
      </Button>

      <div className={classes.memberGrid}>
        {groupData.Leader && (
          <Paper className={`${classes.memberSlot} ${classes.leaderSlot}`} elevation={3}>
            <div className={classes.memberName}>
              <FontAwesomeIcon icon={["fas", "crown"]} className={classes.leaderIcon} />
              {groupData.Leader.Name}
            </div>
            <div className={classes.leaderNote}>Leader cannot be kicked</div>
          </Paper>
        )}

        {groupData.Members &&
          groupData.Members.map((member, index) => (
            <Paper key={index} className={classes.memberSlot} elevation={3}>
              <div className={classes.memberName}>
                <FontAwesomeIcon icon={["fas", "user"]} className={classes.memberIcon} />
                {member.Name}
              </div>
              <div className={classes.kickButton} onClick={() => handleKickMember(member.Cid, index)}>
                <FontAwesomeIcon icon={["fas", "user-minus"]} className={classes.kickIcon} />
                Kick
              </div>
            </Paper>
          ))}
      </div>

      <Dialog
        open={addingMember}
        onClose={() => setAddingMember(false)}
        PaperProps={{
          style: {
            backgroundColor: "#1e1e1e",
            color: "white",
            borderRadius: "10px",
            boxShadow: `0 0 20px ${themeColor}`,
          },
        }}
      >
        <DialogTitle className={classes.dialogTitle}>
          <FontAwesomeIcon icon={["fas", "user-plus"]} style={{ marginRight: "10px" }} />
          Add Group Member
        </DialogTitle>
        <Divider style={{ backgroundColor: themeColor, opacity: 0.5 }} />
        <DialogContent>
          <TextField
            autoFocus
            margin="dense"
            id="cid"
            label="State Id"
            type="text"
            fullWidth
            value={memberCid}
            onChange={(e) => setMemberCid(e.target.value)}
            InputLabelProps={{
              style: { color: "#ccc" },
            }}
            InputProps={{
              style: { color: "white" },
            }}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setAddingMember(false)} style={{ color: "#ccc" }}>
            Cancel
          </Button>
          <Button onClick={handleAddMember} className={classes.dialogButton}>
            Add Member
          </Button>
        </DialogActions>
      </Dialog>
    </div>
  )
}

