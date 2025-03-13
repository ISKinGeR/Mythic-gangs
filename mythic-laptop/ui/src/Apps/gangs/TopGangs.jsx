import React, { useEffect, useState } from 'react';
import { makeStyles } from "@mui/styles"
import {
  Typography,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
} from "@mui/material"
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome"
import Nui from "../../util/Nui"

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
    tableContainer: {
      width: "80%",
      margin: "0 auto",
      backgroundColor: "rgba(30, 30, 30, 0.7)",
      borderRadius: "10px",
      boxShadow: `0 0 15px ${themeColor}`,
      maxHeight: "70vh",
    },
    table: {
      minWidth: 600,
    },
    tableHeader: {
      backgroundColor: "rgba(40, 40, 40, 0.9)",
      "& th": {
        color: themeColor,
        fontWeight: "bold",
        fontSize: "16px",
      },
    },
    tableRow: {
      "&:nth-of-type(odd)": {
        backgroundColor: "rgba(50, 50, 50, 0.5)",
      },
      "&:hover": {
        backgroundColor: "rgba(61, 61, 255, 0.1)",
        transition: "background-color 0.3s",
      },
    },
    rankCell: {
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      fontWeight: "bold",
      fontSize: "20px",
    },
    rankIcon: {
      marginRight: "10px",
      color: "gold",
    },
    gangNameCell: {
      fontWeight: "bold",
      fontSize: "16px",
    },
    progressionChip: {
      fontWeight: "bold",
      color: "white",
    },
    graffitiCell: {
      fontWeight: "bold",
      fontSize: "16px",
    },
    emptyMsg: {
      width: "100%",
      textAlign: "center",
      fontSize: "24px",
      fontWeight: "bold",
      marginTop: "22%",
      color: themeColor,
    },
    loader: {
      display: "flex",
      justifyContent: "center",
      alignItems: "center",
      height: "100%",
      flexDirection: "column",
    },
    loaderText: {
      color: themeColor,
      fontSize: 18,
      marginTop: 10,
      fontWeight: "bold",
    },
  }))

export default function TopGangs({ themeColor = "#e412ca" }) {
  const classes = useStyles(themeColor)()
  const [topGangs, setTopGangs] = useState({})
  const [loading, setLoading] = useState(true)

  // Define progression levels
  const progressionLevels = [
    { level: "Known", required: 4, color: "#607d8b" },
    { level: "Well-Known", required: 8, color: "#4caf50" },
    { level: "Established", required: 16, color: "#2196f3" },
    { level: "Respected", required: 24, color: "#ff9800" },
    { level: "Feared", required: 36, color: "#f44336" },
    { level: "Powerful", required: 54, color: themeColor },
  ]

  // Function to determine progression level based on graffiti count
  const getProgressionLevel = (graffitiCount) => {
    for (let i = progressionLevels.length - 1; i >= 0; i--) {
      if (graffitiCount >= progressionLevels[i].required) {
        return progressionLevels[i]
      }
    }
    return { level: "Unknown", required: 0, color: "#9e9e9e" }
  }

  useEffect(() => {
    fetchTopGangs()
  }, [])

  const fetchTopGangs = async () => {
    setLoading(true)
    try {
		// console.log("Try to Fetch!");
		const response = await (await Nui.send("Unknown/FetchTopGang")).json()
		// console.log(await Nui.send("Unknown/FetchTopGang"));
		if (response) {
		  setTopGangs(response)
		}
    } catch (error) {
      console.error("Error fetching top gangs:", error)
      setTopGangs({})
    }
    setLoading(false)
  }

  if (loading) {
    return (
      <div className={classes.wrapper}>
        <Typography variant="h4" className={classes.title}>
          Top Gangs
        </Typography>
        <div className={classes.loader}>
          <FontAwesomeIcon icon={["fas", "spinner"]} spin size="3x" color={themeColor} />
          <div className={classes.loaderText}>Loading top gangs data...</div>
        </div>
      </div>
    )
  }

  // Convert the object to an array of [gangName, graffitiCount] pairs and sort by count
  const sortedGangs = Object.entries(topGangs).sort((a, b) => b[1] - a[1])

  if (sortedGangs.length === 0) {
    return (
      <div className={classes.wrapper}>
        <Typography variant="h4" className={classes.title}>
          Top Gangs
        </Typography>
        <div className={classes.emptyMsg}>
          <FontAwesomeIcon icon={["fas", "chart-bar"]} size="2x" style={{ marginBottom: "15px" }} />
          <div>No gang data available</div>
        </div>
      </div>
    )
  }

  return (
    <div className={classes.wrapper}>
      <Typography variant="h4" className={classes.title}>
        Top Gangs
      </Typography>

      <TableContainer component={Paper} className={classes.tableContainer}>
        <Table className={classes.table} stickyHeader>
          <TableHead className={classes.tableHeader}>
            <TableRow>
              <TableCell align="center" width="20%">
                Rank
              </TableCell>
              <TableCell align="left" width="45%">
                Gang Name
              </TableCell>
              <TableCell align="center" width="35%">
                Progression Level
              </TableCell>
              {/* <TableCell align="center" width="25%">
                Graffitis
              </TableCell> */}
            </TableRow>
          </TableHead>
          <TableBody>
            {sortedGangs.map(([gangName, graffitiCount], index) => {
              const progression = getProgressionLevel(graffitiCount)

              return (
                <TableRow key={gangName} className={classes.tableRow}>
                  <TableCell align="center" className={classes.rankCell}>
                    {index < 3 && (
                      <FontAwesomeIcon
                        icon={["fas", "trophy"]}
                        className={classes.rankIcon}
                        style={{ color: index === 0 ? "gold" : index === 1 ? "silver" : "#cd7f32" }}
                      />
                    )}
                    {index + 1}
                  </TableCell>
                  <TableCell align="left" className={classes.gangNameCell}>
                    {gangName}
                  </TableCell>
                  <TableCell align="center">
                    <Chip
                      label={progression.level}
                      style={{
                        backgroundColor: progression.color,
                        color: "white",
                        fontWeight: "bold",
                      }}
                      className={classes.progressionChip}
                    />
                  </TableCell>
                  {/* <TableCell align="center" className={classes.graffitiCell}>
                    {graffitiCount}
                  </TableCell> */}
                </TableRow>
              )
            })}
          </TableBody>
        </Table>
      </TableContainer>
    </div>
  )
}

