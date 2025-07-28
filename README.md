# CCTrains

A ComputerCraft train management system for Minecraft that allows automated control of minecart networks. This project provides scripts to coordinate train movements between stations, manage intersections, and handle arrival/departure sequences.

## Overview

CCTrains uses a network of ComputerCraft computers to create a sophisticated railway system without requiring any additional mods. The system uses wireless and wired modems to communicate between the different components of the network.

## Requirements

- Minecraft with ComputerCraft installed
- No additional mods required!

## Project Status

**VERY EARLY DEVELOPMENT**

The project is currently in its initial development phase. Basic communication between computers has been established, but  features are still being implemented.

## Components

### Central Controller (CC)

The central authority that manages all stations in the network. It:
- Discovers and registers stations on the network
- Assigns communication channels to each station
- Will manage global train routing
- Controls system-wide intersections

### Stations

Train stations that communicate with the Central Controller and manage local operations:
- Control arrival and departure of trains
- Manage their own local intersections
- Direct trains to specific rail stops within the station
- Control powered rails for train movement

### Intersections

Junction points that route trains to the correct track:
- Receive commands from stations
- Control redstone relays to switch track direction

## Incoming Features

- Train scheduling system
- Traffic management to avoid collisions
- Station platform management
- Multi-destination routing
- Train presence detection
- Monitor Timetable system
- Web-based monitoring interface (maybe)

## Usage

The system is still in early development, it does not make sense to use it yet, but the basic setup involves:

1. Start intersections first
2. Start the stations and have them connect to intersections
3. Start the central controller and have it connect to stations

The system will automatically discover and establish communication between components.

## Contributing

As this project is in early development, contributions and suggestions are welcome!

## License

This project is licensed under the [MIT License](LICENSE).
