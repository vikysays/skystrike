#include <QDir>
#include <QFile>
#include <QTemporaryDir>
#include <QtTest>

#include "backend.h"
#include "theme.h"
#include "translator.h"

class SkystrikeTests : public QObject {
    Q_OBJECT

private slots:
    void primaryActionCounts() {
        Backend backend;
        const int before = backend.fireTrigger();
        backend.primaryAction();
        QCOMPARE(backend.fireTrigger(), before + 1);
    }

    void scoreRescueAndNavalCombatIncrements() {
        QTemporaryDir dir;
        Backend backend(dir.path() + "/test_stats.json");
        QCOMPARE(backend.score(), 0);
        QCOMPARE(backend.rescues(), 0);
        QCOMPARE(backend.shipsDestroyed(), 0);

        backend.recordRescue();
        QCOMPARE(backend.rescues(), 1);
        QCOMPARE(backend.score(), 500);

        backend.recordPlaneDestroyed();
        QCOMPARE(backend.planesDestroyed(), 1);
        QCOMPARE(backend.score(), 650);

        backend.recordShipDestroyed();
        QCOMPARE(backend.shipsDestroyed(), 1);
        QCOMPARE(backend.score(), 1450);
    }

    void bossDefeatAdvancesWave() {
        QTemporaryDir dir;
        Backend backend(dir.path() + "/test_stats.json");
        QCOMPARE(backend.level(), 1);
        QCOMPARE(backend.maxLevels(), 3);
        QCOMPARE(backend.weaponTier(), 1);
        QCOMPARE(backend.bossName(), QString("Iron Vulture Bomber"));
        QCOMPARE(backend.theaterName(), QString("Coral Sea Sunset Archipelago"));
        QCOMPARE(backend.victory(), false);

        // Defeating Level 1 Boss advances to Level 2 & unlocks Tier 2 weapons
        backend.recordMothershipDefeated();
        QCOMPARE(backend.mothershipsDefeated(), 1);
        QCOMPARE(backend.level(), 2);
        QCOMPARE(backend.weaponTier(), 2);
        QCOMPARE(backend.bossName(), QString("Storm Valkyrie Gunship"));
        QCOMPARE(backend.theaterName(), QString("Arctic Aurora Glacier Strait"));
        QCOMPARE(backend.victory(), false);
        QVERIFY(backend.score() >= 2500);

        // Defeating Level 2 Boss advances to Level 3 & unlocks Tier 3 weapons
        backend.recordMothershipDefeated();
        QCOMPARE(backend.mothershipsDefeated(), 2);
        QCOMPARE(backend.level(), 3);
        QCOMPARE(backend.weaponTier(), 3);
        QCOMPARE(backend.bossName(), QString("Sky Titan Dreadnought"));
        QCOMPARE(backend.theaterName(), QString("Volcanic Lightning Red Sea"));
        QCOMPARE(backend.victory(), false);

        // Defeating Level 3 Final Boss completes the 3-level campaign with victory!
        backend.recordMothershipDefeated();
        QCOMPARE(backend.mothershipsDefeated(), 3);
        QCOMPARE(backend.level(), 3);
        QCOMPARE(backend.victory(), true);
    }

    void themeFallsBack() {
        QTemporaryDir dir;
        Theme theme(dir.path());
        QCOMPARE(theme.accent(), QString("#FFD60A"));
        QCOMPARE(theme.accentForeground(), QString("black"));
    }

    void themeReadsAccent() {
        QTemporaryDir dir;
        QDir(dir.path()).mkpath("theme");
        QFile colors(dir.path() + "/theme/colors.toml");
        QVERIFY(colors.open(QIODevice::WriteOnly));
        colors.write("accent = \"#112233\"\n");
        colors.close();

        Theme theme(dir.path());
        QCOMPARE(theme.accent(), QString("#112233"));
        QCOMPARE(theme.accentForeground(), QString("white"));
    }

    void themeFollowsHyprlandRounding() {
        QTemporaryDir dir;
        const QString response = dir.filePath("response.json"), command = dir.filePath("hyprctl");
        auto write = [](const QString &path, const QByteArray &data) {
            QFile file(path);
            return file.open(QIODevice::WriteOnly) && file.write(data) == data.size();
        };
        QVERIFY(write(command, "#!/bin/sh\ncat '" + response.toUtf8() + "'\n"));
        QVERIFY(QFile::setPermissions(command, QFile::ReadOwner | QFile::WriteOwner | QFile::ExeOwner));
        QVERIFY(write(response, "{\"int\":0}"));

        Theme theme(dir.path(), nullptr, command);
        QCOMPARE(theme.radius(), 0);
        QVERIFY(write(response, "{\"int\":6}"));
        QTRY_COMPARE(theme.radius(), 6);
    }

    void translatorFallsBackToEnglish() {
        QTemporaryDir dir;
        Translator translator(dir.path() + "/language", dir.path());
        QCOMPARE(translator.language(), QString("en"));
        QVERIFY(translator.translate("Main", "Sky Strike").isNull());
    }

    void translatorFollowsTheLanguageFile() {
        QTemporaryDir dir;
        write(dir.path() + "/language", "da\n");
        write(dir.path() + "/da.json", R"({"Sky Strike": "Himmelangreb", "Quit": "Afslut"})");

        Translator translator(dir.path() + "/language", dir.path());
        QCOMPARE(translator.language(), QString("da"));
        QCOMPARE(translator.translate("Main", "Sky Strike"), QString("Himmelangreb"));
        QCOMPARE(translator.translate("Main", "Quit"), QString("Afslut"));
        QVERIFY(translator.translate("Main", "Nonexistent").isNull());
    }

    void translatorPicksPluralForms() {
        QTemporaryDir dir;
        write(dir.path() + "/language", "da\n");
        write(dir.path() + "/en.json", R"({"%n planes": {"one": "%n plane", "other": "%n planes"}})");
        write(dir.path() + "/da.json", R"({"%n planes": {"one": "%n fly", "other": "%n fly"}})");

        Translator translator(dir.path() + "/language", dir.path());
        QCOMPARE(translator.translate("Main", "%n planes", nullptr, 1), QString("%n fly"));
        QCOMPARE(translator.translate("Main", "%n planes", nullptr, 5), QString("%n fly"));
    }

private:
    static void write(const QString &path, const QByteArray &contents) {
        QFile file(path);
        QVERIFY(file.open(QIODevice::WriteOnly));
        file.write(contents);
    }
};

QTEST_MAIN(SkystrikeTests)
#include "skystrike_tests.moc"
