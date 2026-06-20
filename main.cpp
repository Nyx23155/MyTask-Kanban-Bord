#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "databasemanager.h"
#include "taskmodel.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    DatabaseManager dbManager;
    dbManager.initDatabase();

    TaskModel taskModel;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("taskModel", &taskModel);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("MyTask", "Main");

    return app.exec();
}