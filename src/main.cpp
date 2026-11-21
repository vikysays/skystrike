// skystrike — City defense aeroplane combat game for Omarchy.

#include <QDir>
#include <QFile>
#include <QGuiApplication>
#include <QIcon>
#include <QJsonDocument>
#include <QJsonObject>
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
            "description: City defense aeroplane combat game for Omarchy.\n"
            "---\n\n"
            "# Sky Strike CLI\n\n"
            "- `skystrike status --json`: Inspect game high score, statistics, and wave progress.\n"
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
            {QStringLiteral("mothershipsDefeated"), backend.mothershipsDefeated()},
            {QStringLiteral("wave"), backend.wave()}
        };
        if (jsonOut) {
            QTextStream(stdout) << QJsonDocument(out).toJson(QJsonDocument::Compact) << "\n";
        } else {
            QTextStream(stdout) << "Sky Strike Stats:\n"
                                << "  High Score: " << backend.highScore() << "\n"
                                << "  Current Wave: " << backend.wave() << "\n"
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
    if (argc > 1 && QString::fromUtf8(argv[1]) != QLatin1String("open")) {
        qputenv("QT_QPA_PLATFORM", QByteArrayLiteral("offscreen"));
        QGuiApplication app(argc, argv);
        return runCli(argc, argv);
    }

    QGuiApplication app(argc, argv);
    app.setApplicationName("skystrike");
    app.setApplicationVersion("0.1.0");

    app.setDesktopFileName("skystrike");
    app.setWindowIcon(QIcon::fromTheme("skystrike"));

    QQuickStyle::setStyle("Material");

    Translator translator;
    app.installTranslator(&translator);

    Theme theme;
    Backend backend;

    QQmlApplicationEngine engine;
    QObject::connect(&translator, &Translator::changed, &engine, &QQmlEngine::retranslate);
    engine.rootContext()->setContextProperty("translator", &translator);
    engine.rootContext()->setContextProperty("theme", &theme);
    engine.rootContext()->setContextProperty("backend", &backend);
    engine.load(QUrl("qrc:/Main.qml"));
    if (engine.rootObjects().isEmpty())
        return 1;

    return app.exec();
}
