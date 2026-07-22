#include "taskmodel.h"
#include <QJsonArray>

TaskModel::TaskModel(QObject *parent) : QAbstractListModel(parent) {
    m_timer = new QTimer(this);
    connect(m_timer, &QTimer::timeout, this, &TaskModel::checkDeadlines);
    m_timer->start(30000);

    m_networkManager = new QNetworkAccessManager(this);
    m_motivationQuote = "Завантаження натхнення...";
    fetchMotivation();
    loadTasks();
}

int TaskModel::rowCount(const QModelIndex &parent) const {
    Q_UNUSED(parent);
    return m_tasks.count();
}

QVariant TaskModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() >= m_tasks.count()) return QVariant();

    const Task &task = m_tasks[index.row()];
    if (role == IdRole) return task.id;
    if (role == TitleRole) return task.title;
    if (role == ColumnNameRole) return task.columnName;
    if (role == CompletedRole) return task.isCompleted;
    if (role == DeadlineRole) return task.deadline;

    return QVariant();
}

QHash<int, QByteArray> TaskModel::roleNames() const {
    QHash<int, QByteArray> roles;
    roles[IdRole] = "id";
    roles[TitleRole] = "title";
    roles[ColumnNameRole] = "columnName";
    roles[CompletedRole] = "isCompleted";
    roles[DeadlineRole] = "deadline";
    return roles;
}

int TaskModel::count() const { return m_tasks.count(); }
QVariantList TaskModel::columns() const { return m_columns; }
QString TaskModel::motivationQuote() const { return m_motivationQuote; }

// REST API (ZenQuotes)
void TaskModel::fetchMotivation() {
    QNetworkRequest request((QUrl("https://zenquotes.io/api/random")));
    QNetworkReply *reply = m_networkManager->get(request);

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        if (reply->error() == QNetworkReply::NoError) {
            QByteArray response_data = reply->readAll();
            QJsonDocument json = QJsonDocument::fromJson(response_data);

            if (json.isArray() && !json.array().isEmpty()) {
                QJsonObject obj = json.array().first().toObject();
                QString quote = obj["q"].toString();
                QString author = obj["a"].toString();
                m_motivationQuote = "«" + quote + "» — " + author;
            } else {
                m_motivationQuote = "Помилка обробки цитати.";
            }
        } else {
            m_motivationQuote = "Немає підключення до мережі.";
        }
        emit motivationQuoteChanged();
        reply->deleteLater();
    });
}

void TaskModel::loadTasks() {
    beginResetModel();

    m_columns.clear();
    QSqlQuery colQuery("SELECT name, color, deadline FROM columns ORDER BY id");
    while (colQuery.next()) {
        QVariantMap col;
        col["name"] = colQuery.value(0).toString();
        col["color"] = colQuery.value(1).toString();
        col["deadline"] = colQuery.value(2).toString();
        m_columns.append(col);
    }
    emit columnsChanged();

    m_tasks.clear();
    QSqlQuery query("SELECT id, title, column_name, is_completed, deadline FROM tasks");
    while (query.next()) {
        m_tasks.append({
            query.value(0).toInt(),
            query.value(1).toString(),
            query.value(2).toString(),
            query.value(3).toBool(),
            query.value(4).toString()
        });
    }
    endResetModel();
    emit countChanged();

    checkDeadlines();
}

void TaskModel::checkDeadlines() {
    QString currentTimeStr = QDateTime::currentDateTime().toString("dd.MM.yyyy HH:mm");

    for (const Task &task : m_tasks)
    {
        if (!task.isCompleted && task.deadline == currentTimeStr) {
            if (!m_notifiedTaskIds.contains(task.id)) {
                m_notifiedTaskIds.insert(task.id);
                emit deadlineRing(task.id, task.title);
            }
        }
    }
}

void TaskModel::addColumn(const QString &name, const QString &color) {
    QSqlQuery query;
    query.prepare("INSERT INTO columns (name, color, deadline) VALUES (:name, :color, '')");
    query.bindValue(":name", name);
    query.bindValue(":color", color);
    if (query.exec()) loadTasks();
}

void TaskModel::deleteColumn(const QString &name) {
    QSqlQuery query;
    query.prepare("DELETE FROM tasks WHERE column_name = :name");
    query.bindValue(":name", name);
    query.exec();

    query.prepare("DELETE FROM columns WHERE name = :name");
    query.bindValue(":name", name);
    if (query.exec()) loadTasks();
}

void TaskModel::updateColumn(const QString &oldName, const QString &newName, const QString &newColor, const QString &newDeadline) {
    QSqlQuery query;
    query.prepare("UPDATE columns SET name = :newName, color = :newColor, deadline = :newDeadline WHERE name = :oldName");
    query.bindValue(":newName", newName);
    query.bindValue(":newColor", newColor);
    query.bindValue(":newDeadline", newDeadline);
    query.bindValue(":oldName", oldName);

    if (query.exec()) {
        QSqlQuery updateTasks;
        updateTasks.prepare("UPDATE tasks SET column_name = :newName WHERE column_name = :oldName");
        updateTasks.bindValue(":newName", newName);
        updateTasks.bindValue(":oldName", oldName);
        updateTasks.exec();
        loadTasks();
    }
}

void TaskModel::addTask(const QString &title, const QString &columnName) {
    QSqlQuery query;
    query.prepare("INSERT INTO tasks (title, column_name, is_completed, deadline) VALUES (:title, :col, 0, '')");
    query.bindValue(":title", title);
    query.bindValue(":col", columnName);
    if (query.exec()) loadTasks();
}

void TaskModel::updateTaskDetails(int taskId, const QString &newTitle, const QString &newDeadline) {
    QSqlQuery query;
    query.prepare("UPDATE tasks SET title = :title, deadline = :deadline WHERE id = :id");
    query.bindValue(":title", newTitle);
    query.bindValue(":deadline", newDeadline);
    query.bindValue(":id", taskId);
    if (query.exec()) {
        m_notifiedTaskIds.remove(taskId);
        loadTasks();
    }
}

void TaskModel::updateTaskColumn(int taskId, const QString &newColumnName) {
    QSqlQuery query;
    query.prepare("UPDATE tasks SET column_name = :col WHERE id = :id");
    query.bindValue(":col", newColumnName);
    query.bindValue(":id", taskId);
    if (query.exec()) loadTasks();
}

void TaskModel::toggleTaskCompletion(int taskId, bool isCompleted) {
    QSqlQuery query;
    query.prepare("UPDATE tasks SET is_completed = :comp WHERE id = :id");
    query.bindValue(":comp", isCompleted ? 1 : 0);
    query.bindValue(":id", taskId);
    if (query.exec()) loadTasks();
}

void TaskModel::deleteTask(int taskId) {
    QSqlQuery query;
    query.prepare("DELETE FROM tasks WHERE id = :id");
    query.bindValue(":id", taskId);
    if (query.exec()) loadTasks();
}