# Smart Structure Pro

Smart Structure Pro is a custom MetaTrader 5 (MT5) market structure analysis tool developed in **MQL5**. The project is designed to identify and visualize institutional market structure concepts to help traders make informed trading decisions.

## Features

### Current Features

* Swing High and Swing Low detection
* Market Structure visualization
* Break of Structure (BoS) detection
* Change of Character (CHoCH) detection
* Dynamic structure line drawing
* Configurable user inputs
* Modular codebase using `.mqh` include files

## Planned Features

The following features are planned as part of the Smart Structure Pro roadmap:

* Fair Value Gap (FVG) detection
* Supply and Demand Zone identification
* Rally-Base-Rally (RBR) detection
* Drop-Base-Drop (DBD) detection
* Rally-Base-Drop (RBD) detection
* Drop-Base-Rally (DBR) detection
* Order Block detection
* Liquidity Sweep detection
* Equal Highs and Equal Lows
* Premium and Discount Zones
* Multi-Timeframe (MTF) Structure Analysis
* Trend Strength Filter
* ATR Volatility Filter
* Smart Alerts (Popup, Push Notification, Email)
* On-chart Dashboard
* Performance optimization for faster chart scanning

## Project Structure

```
Smart-Structure-Pro/
│
├── SmartStructureBot.mq5      # Main Expert Advisor / Indicator
├── Drawing.mqh                # Drawing and chart object functions
├── Structure.mqh              # Market structure logic
├── SwingDetector.mqh          # Swing detection engine
└── README.md
```

## Development Goals

This project aims to provide a professional-grade Smart Money Concepts (SMC) analysis tool for MetaTrader 5 by combining clean market structure detection with institutional trading concepts.

The long-term objective is to evolve Smart Structure Pro into a complete market analysis framework capable of identifying high-probability trading opportunities with minimal chart clutter.

## Technologies

* MetaTrader 5
* MQL5
* Git
* GitHub
* Visual Studio Code
* MetaEditor

## Installation

1. Clone this repository.
2. Copy the project files into your MT5 `MQL5` directory.
3. Open the project in MetaEditor.
4. Compile the project.
5. Attach the indicator or Expert Advisor to a chart.

## Version

Current Version: **v0.1**

## Author

Developed by Joseph Otieno.

---

This project is under active development. New features, optimizations, and improvements will be added continuously as development progresses.
