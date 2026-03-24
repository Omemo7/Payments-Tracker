# Payments Tracker 💰

A clean, efficient mobile application for personal finance management. Built with **Flutter**, this app allows users to track expenses across multiple accounts, visualize spending habits, and maintain offline records using a local database.

## 📱 Project Overview

This application solves the problem of scattered financial tracking by providing a unified interface for logging daily transactions. It emphasizes data persistence and user-friendly visualization of monthly and daily expenditures.

## 🚀 Key Features

* **Multi-Account Management:** Create and manage different financial accounts (e.g., Bank, Cash, Savings) with dedicated logic for balance tracking.
* **Transaction Logging:** Comprehensive form interfaces to record transaction amounts, specific categories, and dates with validation.
* **Visual Analytics:**
    * **Daily Breakdown:** Drill-down views to inspect detailed transaction logs for specific dates.
    * **Monthly Summary:** High-level dashboard showing total income vs. expenses to track financial health over time.
* **Local Persistence:** Robust offline data storage using a custom SQLite implementation with structured tables for Accounts and Transactions.
* **Custom UI Components:** A consistent design system using modular, reusable widgets for cards, navigation, and input fields.

## 🏗 Architecture & Design

The project follows a **modular architecture** that separates data persistence from the user interface:

* **Database Layer:** Manages the SQLite database connection, schema creation, and CRUD operations for financial records.
* **Models:** Strongly typed data classes ensure type safety and consistent data parsing throughout the application.
* **Screens:** Distinct UI modules for Dashboards, Transaction Entry, and Summaries, keeping the presentation logic decoupled.
* **Widgets:** A library of reusable UI components used to reduce code duplication and maintain a consistent look and feel.

## 🛠 Tech Stack

* **Framework:** Flutter
* **Language:** Dart
* **Database:** SQFlite (Local Storage)
* **State Management:** Modular State Handling
