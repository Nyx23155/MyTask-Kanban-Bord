#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "databasemanager.h"
#include "taskmodel.h"
#include "languagemanager.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;


    DatabaseManager dbManager;
    dbManager.initDatabase();

    LanguageManager langManager(&engine);
    engine.rootContext()->setContextProperty("langManager", &langManager);

    TaskModel taskModel;
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