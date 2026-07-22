#pragma once
#include <QObject>
#include <QTranslator>
#include <QQmlEngine>
#include <QGuiApplication>

class LanguageManager : public QObject
{
    Q_OBJECT
public:
    explicit LanguageManager(QQmlEngine *engine, QObject *parent = nullptr);

    Q_INVOKABLE void setLanguage(const QString &languageCode);

private:
    QTranslator m_translator;
    QQmlEngine *m_engine;
};