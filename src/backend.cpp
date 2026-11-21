#include "backend.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>

Backend::Backend(const QString &configPath, QObject *parent)
    : QObject(parent),
      m_configPath(configPath.isEmpty()
                       ? QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) + "/omarchy/skystrike.json"
                       : configPath) {
    loadStats();
}

void Backend::primaryAction() {
    ++m_fireTrigger;
    emit fireTriggerChanged();
}

void Backend::addScore(int points) {
    if (points <= 0)
        return;
    m_score += points;
    emit scoreChanged();
    if (m_score > m_highScore) {
        m_highScore = m_score;
        emit highScoreChanged();
        saveStats();
    }
}

void Backend::recordRescue() {
    ++m_rescues;
    emit rescuesChanged();
    addScore(500);
    setStatusMessage(QStringLiteral("PARATROOPER RESCUED! +500"));
}

void Backend::recordPlaneDestroyed() {
    ++m_planesDestroyed;
    emit planesDestroyedChanged();
    addScore(150);
}

void Backend::recordShipDestroyed() {
    ++m_shipsDestroyed;
    emit shipsDestroyedChanged();
    addScore(800);
    setStatusMessage(QStringLiteral("WARSHIP SUNK! +800"));
}

void Backend::recordMothershipDefeated() {
    ++m_mothershipsDefeated;
    emit mothershipsDefeatedChanged();
    addScore(2500);
    setStatusMessage(QStringLiteral("MOTHERSHIP DESTROYED! +2500"));
    nextWave();
}

void Backend::nextWave() {
    ++m_wave;
    emit waveChanged();
    setStatusMessage(QStringLiteral("WAVE %1").arg(m_wave));
}

void Backend::togglePause() {
    m_paused = !m_paused;
    emit pausedChanged();
}

void Backend::resetGame() {
    m_score = 0;
    m_rescues = 0;
    m_planesDestroyed = 0;
    m_shipsDestroyed = 0;
    m_mothershipsDefeated = 0;
    m_wave = 1;
    m_paused = false;
    emit scoreChanged();
    emit rescuesChanged();
    emit planesDestroyedChanged();
    emit shipsDestroyedChanged();
    emit mothershipsDefeatedChanged();
    emit waveChanged();
    emit pausedChanged();
    setStatusMessage(QStringLiteral("B-2 SPIRIT AIRBORNE!"));
}

void Backend::setStatusMessage(const QString &msg) {
    m_statusMessage = msg;
    emit statusMessageChanged();
}

void Backend::loadStats() {
    QFile file(m_configPath);
    if (!file.open(QIODevice::ReadOnly))
        return;
    const auto doc = QJsonDocument::fromJson(file.readAll());
    if (doc.isObject()) {
        const auto obj = doc.object();
        m_highScore = obj.value(QStringLiteral("highScore")).toInt(0);
        emit highScoreChanged();
    }
}

void Backend::saveStats() {
    const QString dir = QFileInfo(m_configPath).absolutePath();
    QDir().mkpath(dir);

    QJsonObject obj{
        {QStringLiteral("highScore"), m_highScore}
    };
    QFile file(m_configPath + QStringLiteral(".tmp"));
    if (file.open(QIODevice::WriteOnly)) {
        file.write(QJsonDocument(obj).toJson(QJsonDocument::Compact));
        file.close();
        QFile::remove(m_configPath);
        file.rename(m_configPath);
    }
}
