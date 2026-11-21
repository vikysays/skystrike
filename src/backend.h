#pragma once

#include <QObject>
#include <QString>

class Backend : public QObject {
    Q_OBJECT
    Q_PROPERTY(int score READ score NOTIFY scoreChanged)
    Q_PROPERTY(int highScore READ highScore NOTIFY highScoreChanged)
    Q_PROPERTY(int rescues READ rescues NOTIFY rescuesChanged)
    Q_PROPERTY(int planesDestroyed READ planesDestroyed NOTIFY planesDestroyedChanged)
    Q_PROPERTY(int mothershipsDefeated READ mothershipsDefeated NOTIFY mothershipsDefeatedChanged)
    Q_PROPERTY(int wave READ wave NOTIFY waveChanged)
    Q_PROPERTY(bool paused READ paused NOTIFY pausedChanged)
    Q_PROPERTY(int fireTrigger READ fireTrigger NOTIFY fireTriggerChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)

public:
    explicit Backend(const QString &configPath = {}, QObject *parent = nullptr);

    int score() const { return m_score; }
    int highScore() const { return m_highScore; }
    int rescues() const { return m_rescues; }
    int planesDestroyed() const { return m_planesDestroyed; }
    int mothershipsDefeated() const { return m_mothershipsDefeated; }
    int wave() const { return m_wave; }
    bool paused() const { return m_paused; }
    int fireTrigger() const { return m_fireTrigger; }
    QString statusMessage() const { return m_statusMessage; }

    Q_INVOKABLE void primaryAction();
    Q_INVOKABLE void addScore(int points);
    Q_INVOKABLE void recordRescue();
    Q_INVOKABLE void recordPlaneDestroyed();
    Q_INVOKABLE void recordMothershipDefeated();
    Q_INVOKABLE void nextWave();
    Q_INVOKABLE void togglePause();
    Q_INVOKABLE void resetGame();
    Q_INVOKABLE void setStatusMessage(const QString &msg);

    void saveStats();
    void loadStats();

signals:
    void scoreChanged();
    void highScoreChanged();
    void rescuesChanged();
    void planesDestroyedChanged();
    void mothershipsDefeatedChanged();
    void waveChanged();
    void pausedChanged();
    void fireTriggerChanged();
    void statusMessageChanged();

private:
    QString m_configPath;
    int m_score = 0;
    int m_highScore = 0;
    int m_rescues = 0;
    int m_planesDestroyed = 0;
    int m_mothershipsDefeated = 0;
    int m_wave = 1;
    bool m_paused = false;
    int m_fireTrigger = 0;
    QString m_statusMessage;
};
