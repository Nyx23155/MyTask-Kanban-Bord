#include "databasemanager.h"

DatabaseManager::DatabaseManager(QObject *parent) : QObject(parent) {}

void DatabaseManager::initDatabase() {
    db = QSqlDatabase::addDatabase("QSQLITE");
    db.setDatabaseName("tasks.db");

    if (!db.open()) {
        qWarning() << "Помилка відкриття БД:" << db.lastError().text();
        return;
    }

    QSqlQuery query;
    query.exec(R"(
        CREATE TABLE IF NOT EXISTS columns (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            color TEXT NOT NULL DEFAULT '#0052CC',
            deadline TEXT DEFAULT ''
        )
    )");

    query.exec(R"(
        CREATE TABLE IF NOT EXISTS tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            column_name TEXT NOT NULL,
            is_completed INTEGER DEFAULT 0,
            deadline TEXT DEFAULT ''
        )
    )");

    QSqlQuery check("SELECT COUNT(*) FROM columns");
    if (check.next() && check.value(0).toInt() == 0) {
        query.exec("INSERT INTO columns (name, color, deadline) VALUES ('Ідеї', '#0052CC', ''), ('В процесі', '#FF8B00', '')");
    }

    qDebug() << "База данных успешно инициализирована!";
}