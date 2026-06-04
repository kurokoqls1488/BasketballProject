const express = require('express');
const cors = require('cors');
const bcrypt = require('bcrypt');
const { Pool } = require('pg');
const path = require('path');

console.log('🚀 Запуск сервера...');

const app = express();
const port = 3000;


// ✅ Логирование всех запросов
app.use((req, res, next) => {
    console.log(`📥 ${new Date().toISOString()} | ${req.method} ${req.url}`);
    next();
});

// ✅ CORS - разрешить все origins для теста
app.use(cors({
    origin: true,
    credentials: true,
}));

app.use(express.json());

console.log('✅ Middleware установлены');



// Поднимаемся на один уровень вверх (..) из папки my-api-server, чтобы найти images
const STATIC_PATH = path.join(__dirname, '..', 'images');

// Дебаг-код, который выводит правильный путь:
console.log('******************************************************************');
console.log(`[ДЕБАГ] Текущая директория __dirname: ${__dirname}`);
console.log(`[ДЕБАГ] ОЖИДАЕМЫЙ ПУТЬ К ПАПКЕ IMAGES: ${STATIC_PATH}`);
console.log('******************************************************************');

// Указываем Express, что все запросы, начинающиеся с /images,
// должны обслуживаться файлами из папки, расположенной на уровень выше.
app.use('/images', express.static(STATIC_PATH)); 
console.log('✅ Настройка статических файлов для /images завершена');


const pool = new Pool({
    user: 'postgres',
    host: 'localhost',
    database: 'basketball_db',
    password: '1111',
    port: 5432,
});

console.log('✅ Pool PostgreSQL создан');


// ✅ Тестовые маршруты
app.get('/test-get', (req, res) => {
    console.log('✅ GET /test-get сработал');
    res.status(200).json({ status: 'OK', message: 'GET работает' });
});

app.post('/test-post', (req, res) => {
    console.log('✅ POST /test-post сработал');
    res.status(200).json({ status: 'OK', message: 'POST работает', data: req.body });
});

// ⭐ МАРШРУТ РЕГИСТРАЦИИ
app.post('/register', async (req, res) => {
    console.log('🎯 POST /register вызван', req.body);
    const { nickname, email, password, id_role = 2 } = req.body; 

    if (!nickname || !email || !password) {
        return res.status(400).json({ error: 'Отсутствуют обязательные поля' });
    }
    
    try {
        const userCheck = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
        if (userCheck.rows.length > 0) {
            return res.status(400).json({ error: 'Пользователь с таким email уже существует' });
        }
        
        const hashedPassword = await bcrypt.hash(password, 10);
        
        const result = await pool.query(
            'INSERT INTO users (nickname, email, password, id_role) VALUES ($1, $2, $3, $4) RETURNING id', 
            [nickname, email, hashedPassword, id_role]
        );
        const newUserId = result.rows[0].id;

        const newUser = { 
            id: newUserId, 
            nickname, 
            email, 
            id_role: id_role,
            avatar_url: null,
        };
        
        res.status(201).json({ message: 'Регистрация успешна', user: newUser }); 

    } catch (error) {
        console.error('Ошибка на /register:', error.message);
        res.status(500).json({ error: 'Ошибка сервера при регистрации' });
    }
});

// ✅ Маршрут входа
app.post('/login', async (req, res) => {
    console.log('🎯 POST /login вызван', req.body);
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ error: 'Отсутствуют обязательные поля' });
    }

    try {
        const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
        const user = result.rows[0];

        if (!user) {
            return res.status(401).json({ error: 'Пользователь не найден' });
        }

        const passwordMatch = await bcrypt.compare(password, user.password);

        if (!passwordMatch) {
            return res.status(401).json({ error: 'Неверный пароль' });
        }
        
        res.status(200).json({ 
            message: 'Вход успешен', 
            user: { 
                id: user.id, 
                nickname: user.nickname, 
                email: user.email, 
                id_role: user.id_role,
                avatar_url: user.avatar_url,
            } 
        });

    } catch (error) {
        console.error('Ошибка на /login:', error.message);
        res.status(500).json({ error: 'Ошибка сервера' });
    }
});


// ✅ Маршруты пользователей
app.get('/users', async (req, res) => {
    try {
        const result = await pool.query('SELECT id, nickname, email, id_role FROM users');
        res.status(200).json(result.rows);
    } catch (error) {
        console.error('Ошибка на /users:', error.message);
        res.status(500).json({ error: 'Ошибка базы данных' });
    }
});

// ✅ Маршруты комплексов
app.get('/complexes', async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM complexes');
        res.status(200).json(result.rows);
    } catch (error) {
        console.error('Ошибка на /complexes:', error.message);
        res.status(500).json({ error: 'Ошибка базы данных' });
    }
});

// ✅ Маршрут для тренировок
app.get('/workouts/:complexId', async (req, res) => {
    const { complexId } = req.params;
    try {
        const queryText = 'SELECT * FROM workouts WHERE id_complex = $1 ORDER BY id';
        const result = await pool.query(queryText, [complexId]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Тренировки для данного комплекса не найдены' });
        }

        console.log(`✅ GET /workouts/${complexId} сработал, найдено ${result.rows.length} тренировок`);
        res.status(200).json(result.rows);
    } catch (error) {
        console.error(`Ошибка на /workouts/${complexId}:`, error.message);
        res.status(500).json({ error: 'Ошибка сервера базы данных' });
    }
});

// ⭐ НОВЫЙ МАРШРУТ ДЛЯ УПРАЖНЕНИЙ (Многие-ко-многим)
app.get('/exercises/workouts/:id', async (req, res) => {
    const workoutId = req.params.id;
    console.log(`🎯 GET /exercises/workouts/${workoutId} вызван`);

    try {
        const query = `
            SELECT e.id, e.name_exercise, e.image, e.description 
            FROM exercises e
            JOIN workouts_exercises we ON e.id = we.id_exercise
            WHERE we.id_workout = $1
            ORDER BY e.id
        `;
        
        const result = await pool.query(query, [workoutId]);

        console.log(`✅ Найдено упражнений: ${result.rows.length} для тренировки ${workoutId}`);
        
        // Отправляем массив (даже если он пустой, статус 200, чтобы Flutter не упал)
        res.status(200).json(result.rows);

    } catch (error) {
        console.error(`Ошибка на /exercises/workouts/${workoutId}:`, error.message);
        res.status(500).json({ error: 'Ошибка сервера при получении упражнений' });
    }
});


// ✅ Обработчик 404 — должен быть последним
app.use((req, res) => {
    res.status(404).json({ error: 'Маршрут не найден' });
});


app.listen(port, () => {
    console.log(`✅ Сервер запущен на http://localhost:${port}`);
});