import React, { useEffect, useState, useMemo } from 'react';
import { useSelector } from "react-redux"
import { makeStyles, withStyles } from "@mui/styles"
import { Tab, Tabs } from "@mui/material"
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome"
import { throttle } from "lodash"

import GroupInfo from "./GroupInfo"
import Progression from "./Progression"
import Members from "./Members"
import Chat from "./Chat"
import TopGangs from "./TopGangs"
import Nui from "../../util/Nui"

// New theme color
const themeColor = "#3d3dff"

const useStyles = makeStyles((theme) => ({
  wrapper: {
    height: "100%",
    background: theme.palette.secondary.main,
  },
  header: {
    background: themeColor,
    fontSize: 20,
    padding: 15,
    lineHeight: "50px",
    height: 78,
  },
  content: {
    height: "100%",
    overflow: "hidden",
  },
  headerAction: {},
  emptyMsg: {
    width: "100%",
    textAlign: "center",
    fontSize: 20,
    fontWeight: "bold",
    marginTop: "25%",
    color: "#fff",
  },
  tabPanel: {
    top: 0,
    height: "92.25%",
  },
  list: {
    height: "100%",
    overflow: "auto",
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

const YPTabs = withStyles(() => ({
  root: {
    borderBottom: `1px solid ${themeColor}`,
  },
  indicator: {
    backgroundColor: themeColor,
  },
}))((props) => <Tabs {...props} />)

const YPTab = withStyles(() => ({
  root: {
    width: "20%", // Changed from 25% to 20% since we now have 5 tabs
    "&:hover": {
      color: themeColor,
      transition: "color ease-in 0.15s",
    },
    "&$selected": {
      color: themeColor,
      transition: "color ease-in 0.15s",
    },
    "&:focus": {
      color: themeColor,
      transition: "color ease-in 0.15s",
    },
  },
  selected: {},
  disabled: {
    color: "#333333 !important",
    transition: "color ease-in 0.15s",
  },
}))((props) => <Tab {...props} />)

export default (props) => {
  const classes = useStyles()

  const [loading, setLoading] = useState(false)
  const visible = useSelector((state) => state.laptop.visible)
  const [tab, setTab] = useState(0)
  const [groupData, setGroupData] = useState({})
  const [gangDataLoading, setGangDataLoading] = useState(true)

  const fetch = useMemo(
    () =>
      throttle(async () => {
        if (loading) return
        setLoading(true)
        setGangDataLoading(true)
        try {
          // Fetch gang data
          const gangRes = await (await Nui.send("Unknown/FetchGang")).json()
          console.log("Gang DATA:", JSON.stringify(gangRes, null, 2))
          if (gangRes) {
            setGroupData(gangRes)
          }
        } catch (err) {
          console.log(err)
        }
        setLoading(false)
        setGangDataLoading(false)
      }, 1000),
    [],
  )

  useEffect(() => {
    fetch()
  }, [])

  useEffect(() => {
    if (visible) {
      fetch()
    }
  }, [visible])

  const handleTabChange = (event, tab) => {
    setTab(tab)
  }

  const LoadingComponent = () => (
    <div className={classes.loader}>
      <FontAwesomeIcon icon={["fas", "spinner"]} spin size="3x" color={themeColor} />
      <div className={classes.loaderText}>Loading gang data...</div>
    </div>
  )

  return (
    <div className={classes.wrapper}>
      <div className={classes.content}>
        <div className={classes.tabPanel} role="tabpanel" hidden={tab !== 0} id="group_info">
          {tab === 0 &&
            (gangDataLoading ? <LoadingComponent /> : <GroupInfo groupData={groupData} themeColor={themeColor} />)}
        </div>

        <div className={classes.tabPanel} role="tabpanel" hidden={tab !== 1} id="progression">
          {tab === 1 &&
            (gangDataLoading ? <LoadingComponent /> : <Progression groupData={groupData} themeColor={themeColor} />)}
        </div>

        <div className={classes.tabPanel} role="tabpanel" hidden={tab !== 2} id="members">
          {tab === 2 &&
            (gangDataLoading ? (
              <LoadingComponent />
            ) : (
              <Members groupData={groupData} setGroupData={setGroupData} themeColor={themeColor} />
            ))}
        </div>

        <div className={classes.tabPanel} role="tabpanel" hidden={tab !== 3} id="chat">
          {tab === 3 &&
            (gangDataLoading ? <LoadingComponent /> : <Chat groupData={groupData} themeColor={themeColor} />)}
        </div>

        <div className={classes.tabPanel} role="tabpanel" hidden={tab !== 4} id="top_gangs">
          {tab === 4 && <TopGangs themeColor={themeColor} />}
        </div>

        <div className={classes.tabs}>
          <YPTabs value={tab} onChange={handleTabChange} scrollButtons={false} centered>
            <YPTab icon={<FontAwesomeIcon icon={["fas", "info-circle"]} />} />
            <YPTab icon={<FontAwesomeIcon icon={["fas", "chart-line"]} />} />
            <YPTab icon={<FontAwesomeIcon icon={["fas", "users"]} />} />
            <YPTab icon={<FontAwesomeIcon icon={["fas", "comments"]} />} />
            <YPTab icon={<FontAwesomeIcon icon={["fas", "trophy"]} />} />
          </YPTabs>
        </div>
      </div>
    </div>
  )
}