# Aether Compute Market

A decentralized compute credit marketplace built on the Stacks blockchain using Clarity smart contracts.

## Overview

Aether Compute Market enables a peer-to-peer marketplace where:
- **Providers** stake STX and offer compute resources
- **Users** purchase credits and redeem them for services
- **Credits** expire after 720 blocks to encourage active usage

## Features

- **Provider Registration**: Stake-based validation (50,000 microSTX minimum)
- **Credit System**: Purchase and spend credits with automatic expiration
- **Admin Controls**: Manage credit pricing and marketplace configuration
- **Role-Based Access**: Separate permissions for admins, providers, and users
- **Secure Transfers**: STX custody handled by contract

## Quick Start

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet)
- Node.js 16+

### Installation
```bash
git clone https://github.com/yourusername/aether-compute-market.git
cd aether-compute-market
npm install
