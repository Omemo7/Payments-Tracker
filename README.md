# Payments Tracker 💰

A clean, efficient mobile application for personal finance management. Built with **Flutter**, this app allows users to track expenses across multiple accounts, visualize spending habits, and maintain offline records using a local database.

## 📱 Project Overview

This application solves the problem of scattered financial tracking by providing a unified interface for logging daily transactions. It emphasizes data persistence and user-friendly visualization of monthly and daily expenditures.

## 🚀 Key Features

* **Multi-Account Management:** Create and manage different financial accounts (e.g., Bank, Cash, Savings) with dedicated logic handled in `account_main_screen.dart`.
* **Transaction Logging:** Detailed add/edit functionality (`add_edit_transaction_screen.dart`) to record amounts, categories, and dates.
* **Visual Analytics:**
    * **Daily Breakdown:** View detailed transaction logs for specific days (`daily_details_screen.dart`).
    * **Monthly Summary:** High-level dashboard showing total income vs. expenses (`monthly_summary_screen.dart`).
* **Local Persistence:** Robust offline data storage using a custom `database_helper` with structured SQL tables for Accounts and Transactions.
* **Custom UI Components:** Modular design with reusable widgets like `transaction_list_tile_card` and `daily_summary_card` for consistent styling.

## 🏗 Architecture & Design

The project follows a **modular architecture** separating data logic from UI components:

* **Database Layer:**
    * `database/tables`: Defines schema for `account_table` and `transaction_table`.
    * `database_helper.dart`: Manages CRUD operations and database initialization.
* **Models:** Strongly typed data classes (`account_model.dart`, `transaction_model.dart`) ensuring type safety across the app.
* **Screens:** Distinct UI files for each view (Dashboard, Add Transaction, Summary) to keep the codebase clean.
* **Widgets:** Custom components (`account_card`, `navigation_buttons`) to reduce code duplication and enhance maintainability.

## 🛠 Tech Stack

* **Framework:** Flutter
* **Language:** Dart
* **Database:** SQFlite (Local Storage)
* **State Management:** (Implied via use of Singleton/Providers or `setState` based on structure)
