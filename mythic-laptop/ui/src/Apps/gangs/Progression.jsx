import React from 'react';
import { makeStyles } from "@mui/styles"
import { Paper, Typography } from "@mui/material"
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
    progressionGrid: {
      width: "100%",
      maxHeight: "70vh",
      padding: "0.2vh",
      margin: "0 auto",
      marginTop: "20px",
      overflowY: "auto",
      display: "grid",
      gridTemplateColumns: "repeat(3, 1fr)",
      gridColumnGap: "20px",
      gridRowGap: "20px",
    },
    progressionSlot: {
      width: "100%",
      padding: "20px 0",
      background: "rgba(30, 30, 30, 0.7)",
      borderRadius: "10px",
      transition: "all 0.3s ease",
    },
    unlockedSlot: {
      boxShadow: `0 0 15px ${themeColor}`,
      background: "rgba(40, 40, 40, 0.8)",
    },
    slotTitle: {
      color: "white",
      textAlign: "center",
      fontSize: "20px",
      fontWeight: "bold",
      marginBottom: "10px",
    },
    slotRequirement: {
      color: themeColor,
      fontSize: "16px",
      textAlign: "center",
    },
    emptyMsg: {
      width: "100%",
      textAlign: "center",
      fontSize: "24px",
      fontWeight: "bold",
      marginTop: "22%",
      color: themeColor,
    },
    progressIcon: {
      fontSize: "30px",
      color: themeColor,
      display: "block",
      margin: "0 auto 15px auto",
    },
    lockedIcon: {
      fontSize: "30px",
      color: "#666",
      display: "block",
      margin: "0 auto 15px auto",
    },
  }))

export default function Progression({ groupData, themeColor = "#e412ca" }) {
  const classes = useStyles(themeColor)()

  if (!groupData?.Id) {
    return (
      <div className={classes.wrapper}>
        <Typography variant="h4" className={classes.title}>
          Current Progression
        </Typography>
        <div className={classes.emptyMsg}>
          <FontAwesomeIcon icon={["fas", "lock"]} size="2x" style={{ marginBottom: "15px" }} />
          <div>You must be in a gang to see progression</div>
        </div>
      </div>
    )
  }

  const totalSprays = groupData.TotalSprays || 0

  const progressionLevels = [
    { level: "Known", required: 4, icon: "street-view" },
    { level: "Well-Known", required: 8, icon: "thumbs-up" },
    { level: "Established", required: 16, icon: "building" },
    { level: "Respected", required: 24, icon: "handshake" },
    { level: "Feared", required: 36, icon: "skull" },
    { level: "Powerful", required: 54, icon: "crown" },
  ]

  return (
    <div className={classes.wrapper}>
      <Typography variant="h4" className={classes.title}>
        Current Progression
      </Typography>
      <Typography variant="h6" className={classes.subtitle}>
        Current Graffitis: {totalSprays}
      </Typography>

      <div className={classes.progressionGrid}>
        {progressionLevels.map((level, index) => {
          const isUnlocked = totalSprays >= level.required
          return (
            <Paper
              key={index}
              className={`${classes.progressionSlot} ${isUnlocked ? classes.unlockedSlot : ""}`}
              elevation={3}
            >
              {isUnlocked ? (
                <FontAwesomeIcon icon={["fas", level.icon]} className={classes.progressIcon} />
              ) : (
                <FontAwesomeIcon icon={["fas", "lock"]} className={classes.lockedIcon} />
              )}
              <Typography className={classes.slotTitle}>{isUnlocked ? level.level : "?"}</Typography>
              <Typography className={classes.slotRequirement}>Graffitis Needed: {level.required}</Typography>
            </Paper>
          )
        })}
      </div>
    </div>
  )
}

