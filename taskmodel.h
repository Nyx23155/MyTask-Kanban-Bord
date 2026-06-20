#ifndef TASKMODEL_H
#define TASKMODEL_H

#include <QAbstractListModel>
#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>
#include <QVariantList>
#include <QVariantMap>
#include <QTimer>
#include <QDateTime>
#include <QSet>

// Додаємо бібліотеки для REST API
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>

class TaskModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(QVariantList columns READ columns NOTIFY columnsChanged)

    // Нова властивість для збереження цитати з API
    Q_PROPERTY(QString motivationQuote READ motivationQuote NOTIFY motivationQuoteChanged)

public:
    enum TaskRoles { IdRole = Qt::UserRole + 1, TitleRole, ColumnNameRole, CompletedRole, DeadlineRole };
    explicit TaskModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const;
    QVariantList columns() const;
    QString motivationQuote() const;

    Q_INVOKABLE void loadTasks();

    Q_INVOKABLE void addColumn(const QString &name, const QString &color);
    Q_INVOKABLE void deleteColumn(const QString &name);
    Q_INVOKABLE void updateColumn(const QString &oldName, const QString &newName, const QString &newColor, const QString &newDeadline);

    Q_INVOKABLE void addTask(const QString &title, const QString &columnName);
    Q_INVOKABLE void updateTaskColumn(int taskId, const QString &newColumnName);
    Q_INVOKABLE void toggleTaskCompletion(int taskId, bool isCompleted);
    Q_INVOKABLE void deleteTask(int taskId);
    Q_INVOKABLE void updateTaskDetails(int taskId, const QString &newTitle, const QString &newDeadline);

    // Метод для виклику REST API
    Q_INVOKABLE void fetchMotivation();

signals:
    void countChanged();
    void columnsChanged();
    void deadlineRing(int taskId, QString taskTitle);
    void motivationQuoteChanged();

private slots:
    void checkDeadlines();

private:
    struct Task {
        int id;
        QString title;
        QString columnName;
        bool isCompleted;
        QString deadline;
    };
    QList<Task> m_tasks;
    QVariantList m_columns;

    QTimer *m_timer;
    QSet<int> m_notifiedTaskIds;

    // Змінні для роботи з API
    QString m_motivationQuote;
    QNetworkAccessManager *m_networkManager;
};

#endif // TASKMODEL_H