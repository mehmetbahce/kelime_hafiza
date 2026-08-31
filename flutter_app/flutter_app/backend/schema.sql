-- Kelime Hafıza App - Veritabanı Şeması
-- Melih Duyar tarzı çağrışım kartları

CREATE DATABASE IF NOT EXISTS kelime_hafiza CHARACTER SET utf8mb4 COLLATE utf8mb4_turkish_ci;
USE kelime_hafiza;

CREATE TABLE IF NOT EXISTS categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    color VARCHAR(7) DEFAULT '#F5C518',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS cards (
    id INT AUTO_INCREMENT PRIMARY KEY,
    english_word VARCHAR(100) NOT NULL,
    turkish_meaning VARCHAR(150) NOT NULL,
    association_word VARCHAR(150) NOT NULL,        -- Çağrışım kelimesi (örn: "Laf", "Arma", "Mont")
    mnemonic_sentence TEXT NOT NULL,                -- Akılda kalıcı cümle
    image_path VARCHAR(255) DEFAULT NULL,           -- /uploads/xxx.jpg (orijinal kart görseli)
    category_id INT DEFAULT NULL,
    difficulty ENUM('easy','medium','hard') DEFAULT 'medium',

    -- Spaced Repetition (SM-2 algoritması) alanları
    ease_factor DECIMAL(4,2) DEFAULT 2.50,
    interval_days INT DEFAULT 0,
    repetitions INT DEFAULT 0,
    next_review_date DATE DEFAULT NULL,
    last_reviewed_at DATETIME DEFAULT NULL,

    -- İstatistik
    times_seen INT DEFAULT 0,
    times_correct INT DEFAULT 0,

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
    INDEX idx_next_review (next_review_date),
    INDEX idx_english_word (english_word)
) ENGINE=InnoDB;

-- Örnek kategoriler
INSERT INTO categories (name, color) VALUES
('Genel', '#F5C518'),
('Fiiller', '#4CAF50'),
('Sıfatlar', '#2196F3'),
('İsimler', '#E91E63'),
('Deyimler', '#9C27B0');

-- Örnek kartlar (yüklediğin görsellerden)
INSERT INTO cards (english_word, turkish_meaning, association_word, mnemonic_sentence, category_id) VALUES
('Laugh', 'Gülmek', 'Laf', 'Her LAF''a gülmeyin! Düşünmeden söylenen her laf doğru olmayabilir.', 1),
('Arm', 'Kol', 'Arma', 'Kolunda güzel arma olan gence arkadaşı bakıp: "Kolundaki ARM''ayı beğendim harika!" dedi.', 4),
('Month', 'Ay', 'Mont', 'Hava soğuk bu AY, herkes MONT''unu kırmızı giysin dedi patron.', 4),
('Chef', 'Aşçı', 'Şef', 'Aşçı sinirlendi ve ben şefinizim, beni ŞEFFFFF diye çağıracaksınız.. dedi elemanlara!', 3),
('Snake', 'Yılan', 'Sinek', 'Ssss... SİNEK! diye düşündü yılan sinek görünce.', 4),
('Uncle', 'Amca', 'En kıl', 'Amcan hangisi? EN KILLI olan benim amcam.', 4);
