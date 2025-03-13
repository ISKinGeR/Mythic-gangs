import React from 'react';
import { makeStyles } from "@mui/styles"
import { Button, Paper, Typography } from "@mui/material"
import Nui from "../../util/Nui"
import { useAlert } from "../../hooks"
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome"

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
    infoContainer: {
      display: "flex",
      justifyContent: "center",
      width: "70%",
      margin: "0 auto",
      marginTop: "30px",
    },
    infoCard: {
      background: "rgba(30, 30, 30, 0.7)",
      padding: "20px",
      borderRadius: "10px",
      boxShadow: `0 0 10px ${themeColor}`,
      transition: "transform 0.3s ease",
      "&:hover": {
        transform: "scale(1.03)",
      },
    },
    infoTitle: {
      fontSize: "22px",
      textAlign: "center",
      color: themeColor,
      marginBottom: "10px",
    },
    infoValue: {
      fontSize: "18px",
      textAlign: "center",
      color: "#fff",
    },
    actionContainer: {
      display: "flex",
      justifyContent: "space-between",
      width: "70%",
      margin: "0 auto",
      marginTop: "40px",
    },
    actionCard: {
      background: "rgba(30, 30, 30, 0.7)",
      padding: "20px",
      borderRadius: "10px",
      boxShadow: `0 0 10px ${themeColor}`,
      width: "45%",
      transition: "transform 0.3s ease",
      "&:hover": {
        transform: "scale(1.03)",
      },
    },
    actionButton: {
      background: themeColor,
      color: "white",
      "&:hover": {
        background: "#c010a8",
      },
      marginTop: "15px",
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

export default function GroupInfo({ groupData, themeColor = "#e412ca" }) {
  const classes = useStyles(themeColor)()
  const alert = useAlert()

  const toggleDiscoveredGraffitis = async () => {
    try {
      await Nui.send("Unknown/ToggleDiscoveredGraffitis")
      alert("Toggled discovered graffitis")
    } catch (error) {
      console.error("Error toggling discovered graffitis:", error)
      alert("Error toggling discovered graffitis")
    }
  }

  const toggleContestedGraffitis = async () => {
    try {
      await Nui.send("Unknown/ToggleContestedGraffitis")
      alert("Toggled contested graffitis")
    } catch (error) {
      console.error("Error toggling contested graffitis:", error)
      alert("Error toggling contested graffitis")
    }
  }

  if (!groupData?.Id) {
    return (
      <div className={classes.wrapper}>
        <Typography variant="h4" className={classes.title}>
          Group Information
        </Typography>
        <div className={classes.emptyMsg}>
          <FontAwesomeIcon icon={["fas", "users-slash"]} size="2x" style={{ marginBottom: "15px" }} />
          <div>You are not in a gang</div>
        </div>
      </div>
    )
  }

  return (
    <div className={classes.wrapper}>
      <Typography variant="h4" className={classes.title}>
        Group Information
      </Typography>
      <Typography variant="h6" className={classes.subtitle}>
        Current Group: {groupData?.Label || "No Gang"}
      </Typography>

      <div className={classes.infoContainer}>
        <Paper className={classes.infoCard} elevation={3}>
          <Typography variant="h5" className={classes.infoTitle}>
            <FontAwesomeIcon icon={["fas", "users"]} style={{ marginRight: "10px" }} />
            Current Members
          </Typography>
          <Typography variant="body1" className={classes.infoValue}>
            {1 + (groupData.Members?.length || 0)}
          </Typography>
        </Paper>
      </div>

      <div className={classes.actionContainer}>
        <Paper className={classes.actionCard} elevation={3}>
          <Typography variant="h5" className={classes.infoTitle}>
            <FontAwesomeIcon icon={["fas", "spray-can"]} style={{ marginRight: "10px" }} />
            Discovered Graffiti
          </Typography>
          <div style={{ width: "100%", display: "flex", justifyContent: "center" }}>
            <Button
              variant="contained"
              className={classes.actionButton}
              onClick={toggleDiscoveredGraffitis}
              startIcon={<FontAwesomeIcon icon={["fas", "eye"]} />}
            >
              Toggle Visibility
            </Button>
          </div>
        </Paper>

        <Paper className={classes.actionCard} elevation={3}>
          <Typography variant="h5" className={classes.infoTitle}>
            <FontAwesomeIcon icon={["fas", "exclamation-triangle"]} style={{ marginRight: "10px" }} />
            Contested Graffitis
          </Typography>
          <div style={{ width: "100%", display: "flex", justifyContent: "center" }}>
            <Button
              variant="contained"
              className={classes.actionButton}
              onClick={toggleContestedGraffitis}
              startIcon={<FontAwesomeIcon icon={["fas", "eye"]} />}
            >
              Toggle Visibility
            </Button>
          </div>
        </Paper>
      </div>
    </div>
  )
}