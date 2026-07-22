#include "languagemanager.h"

LanguageManager::LanguageManager(QQmlEngine *engine, QObject *parent)
    : QObject(parent), m_engine(engine) {}

void LanguageManager::setLanguage(const QString &languageCode)
{
    qApp->removeTranslator(&m_translator);

    if (languageCode != "en") {
        if (m_translator.load(":/i18n/" + languageCode + ".qm")) {
            qApp->installTranslator(&m_translator);
        }
    }

    m_engine->retranslate();
}