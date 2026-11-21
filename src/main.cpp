// skystrike — B-2 Spirit stealth bomber air & naval combat game for Omarchy.

#include <QDir>
#include <QFile>
#include <QGuiApplication>
#include <QIcon>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLoggingCategory>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QTextStream>
#include <QUrl>

#include "backend.h"
#include "theme.h"
#include "translator.h"

namespace {
int runCli(int argc, char *argv[]) {
    QStringList args;
    for (int i = 1; i < argc; ++i)
        args.append(QString::fromUtf8(argv[i]));

    const bool jsonOut = args.removeAll(QStringLiteral("--json")) > 0;
    const QString cmd = args.value(0);

    if (cmd == QLatin1String("skill") && args.value(1) == QLatin1String("install")) {
        const QString skillDir = QDir::homePath() + QStringLiteral("/.config/skills/skystrike");
        QDir().mkpath(skillDir);
        QFile file(skillDir + QStringLiteral("/SKILL.md"));
        if (!file.open(QIODevice::WriteOnly)) {
            QTextStream(stderr) << "Failed to write skill file\n";
            return 1;
        }
        file.write(
            "---\n"
            "name: skystrike\n"
            "description: B-2 Spirit stealth bomber air and wartime naval combat game for Omarchy.\n"
            "---\n\n"
            "# Sky Strike CLI\n\n"
            "- `skystrike status --json`: Inspect game high score, ships sunk, planes destroyed, and wave progress.\n"
            "- `skystrike open`: Launch the game window.\n");
        file.close();
        if (jsonOut) {
            QTextStream(stdout) << QJsonDocument(QJsonObject{{QStringLiteral("installed"), file.fileName()}})
                                       .toJson(QJsonDocument::Compact)
                                << "\n";
        } else {
            QTextStream(stdout) << "Installed skill to " << file.fileName() << "\n";
        }
        return 0;
    }

    Backend backend;
    if (cmd == QLatin1String("status")) {
        const QJsonObject out{
            {QStringLiteral("game"), QStringLiteral("skystrike")},
            {QStringLiteral("score"), backend.score()},
            {QStringLiteral("highScore"), backend.highScore()},
            {QStringLiteral("rescues"), backend.rescues()},
            {QStringLiteral("planesDestroyed"), backend.planesDestroyed()},
            {QStringLiteral("shipsDestroyed"), backend.shipsDestroyed()},
            {QStringLiteral("mothershipsDefeated"), backend.mothershipsDefeated()},
            {QStringLiteral("wave"), backend.wave()}
        };
        if (jsonOut) {
            QTextStream(stdout) << QJsonDocument(out).toJson(QJsonDocument::Compact) << "\n";
        } else {
            QTextStream(stdout) << "Sky Strike Stats:\n"
                                << "  High Score: " << backend.highScore() << "\n"
                                << "  Current Wave: " << backend.wave() << "\n"
                                << "  Ships Sunk: " << backend.shipsDestroyed() << "\n"
                                << "  Planes Destroyed: " << backend.planesDestroyed() << "\n"
                                << "  Rescues: " << backend.rescues() << "\n";
        }
        return 0;
    }

    QTextStream(stderr) << "Unknown command: " << cmd << "\n"
                        << "Usage: skystrike [open|status|skill install] [--json]\n";
    return 1;
}
} // namespace

int main(int argc, char *argv[]) {
    // Silence benign xdg-desktop-portal re-registration warnings when launched
    // from an environment that already associated the session D-Bus connection.
    QLoggingCategory::setFilterRules(QStringLiteral("qt.qpa.services.warning=false"));

    if (argc > 1 && QString::fromUtf8(argv[1]) != QLatin1String("open")) {
        qputenv("QT_QPA_PLATFORM", QByteArrayLiteral("offscreen"));
        QGuiApplication app(argc, argv);
        return runCli(argc, argv);
    }

    // Set application metadata and desktop file name BEFORE constructing
    // QGuiApplication so Qt registers the portal app_id only once on startup.
    QCoreApplication::setApplicationName(QStringLiteral("skystrike"));
    QCoreApplication::setApplicationVersion(QStringLiteral("0.2.0"));
    QGuiApplication::setDesktopFileName(QStringLiteral("skystrike"));

    QGuiApplication app(argc, argv);
    app.setWindowIcon(QIcon::fromTheme(QStringLiteral("skystrike")));

    QQuickStyle::setStyle(QStringLiteral("Material"));

    Translator translator;
    app.installTranslator(&translator);

    Theme theme;
    Backend backend;

    QQmlApplicationEngine engine;
    QObject::connect(&translator, &Translator::changed, &engine, &QQmlEngine::retranslate);
    engine.rootContext()->setContextProperty(QStringLiteral("translator"), &translator);
    engine.rootContext()->setContextProperty(QStringLiteral("theme"), &theme);
    engine.rootContext()->setContextProperty(QStringLiteral("backend"), &backend);
    engine.load(QUrl(QStringLiteral("qrc:/Main.qml")));
    if (engine.rootObjects().isEmpty())
        return 1;

    return app.exec();
}
