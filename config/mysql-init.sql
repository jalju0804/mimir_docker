-- MySQL 초기화 스크립트
-- 테스트 데이터베이스 설정

-- 기본 데이터베이스 사용
USE testdb;

-- 테스트 테이블 생성
CREATE TABLE IF NOT EXISTS test_table (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 샘플 데이터 삽입
INSERT INTO test_table (name) VALUES 
('Test User 1'),
('Test User 2'),
('Test User 3');

-- 모니터링용 사용자 생성 (선택사항)
CREATE USER IF NOT EXISTS 'monitor'@'%' IDENTIFIED BY 'monitor123';
GRANT SELECT, PROCESS, REPLICATION CLIENT ON *.* TO 'monitor'@'%';
FLUSH PRIVILEGES;

-- 테이블 확인
SELECT 'MySQL initialized successfully' AS status;
SELECT COUNT(*) as test_records FROM test_table; 