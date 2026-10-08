from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
from mysql.connector import Error
from werkzeug.security import generate_password_hash, check_password_hash
import re
import os
from dotenv import load_dotenv

# Load variables from .env
load_dotenv()

app = Flask(__name__)
CORS(app)


# ============================================================
# DATABASE CONFIGURATION
# ============================================================

DB_CONFIG = {
    "host": os.getenv("DB_HOST"),
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD"),
    "database": os.getenv("DB_NAME")
}


# ============================================================
# DATABASE CONNECTION
# ============================================================

def get_db_connection():
    try:
        connection = mysql.connector.connect(**DB_CONFIG)

        if connection.is_connected():
            return connection

    except Error as e:
        print("Database connection error:", e)

    return None


def close_db(cursor=None, connection=None):
    if cursor is not None:
        try:
            cursor.close()
        except Exception:
            pass

    if connection is not None:
        try:
            if connection.is_connected():
                connection.close()
        except Exception:
            pass


# ============================================================
# HELPERS
# ============================================================

def valid_email(email):
    pattern = r"^[^@\s]+@[^@\s]+\.[^@\s]+$"
    return re.match(pattern, email) is not None


def convert_value(value):
    if value is None:
        return None

    if hasattr(value, "strftime"):
        return value.strftime("%Y-%m-%d %H:%M:%S")

    return value


# ============================================================
# HOME
# ============================================================

@app.route("/", methods=["GET"])
def home():
    return jsonify({
        "success": True,
        "message": "Team App Backend is Running!"
    })


# ============================================================
# DATABASE TEST
# ============================================================

@app.route("/db-test", methods=["GET"])
def db_test():

    connection = get_db_connection()

    if connection is None:
        return jsonify({
            "success": False,
            "message": "MySQL connection failed"
        }), 500

    cursor = None

    try:
        cursor = connection.cursor()
        cursor.execute("SELECT DATABASE()")
        result = cursor.fetchone()

        return jsonify({
            "success": True,
            "message": "MySQL connection successful",
            "database": result[0] if result else None
        })

    except Error as e:
        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:
        close_db(cursor, connection)


# ============================================================
# REGISTER
# ============================================================

@app.route("/register", methods=["POST"])
def register():

    data = request.get_json(silent=True) or {}

    name = str(data.get("name", "")).strip()
    email = str(data.get("email", "")).strip().lower()
    password = str(data.get("password", ""))

    if not name:
        return jsonify({
            "success": False,
            "message": "Name is required"
        }), 400

    if not email:
        return jsonify({
            "success": False,
            "message": "Email is required"
        }), 400

    if not valid_email(email):
        return jsonify({
            "success": False,
            "message": "Invalid email address"
        }), 400

    if len(password) < 6:
        return jsonify({
            "success": False,
            "message": "Password must contain at least 6 characters"
        }), 400

    connection = get_db_connection()

    if connection is None:
        return jsonify({
            "success": False,
            "message": "Database connection failed"
        }), 500

    cursor = None

    try:

        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            """
            SELECT user_id
            FROM users
            WHERE email = %s
            """,
            (email,)
        )

        existing = cursor.fetchone()

        if existing:
            return jsonify({
                "success": False,
                "message": "Email already registered"
            }), 409

        password_hash = generate_password_hash(password)

        cursor.execute(
            """
            INSERT INTO users
            (name, email, password, role)
            VALUES (%s, %s, %s, %s)
            """,
            (
                name,
                email,
                password_hash,
                "Employee"
            )
        )

        connection.commit()

        user_id = cursor.lastrowid

        return jsonify({
            "success": True,
            "message": "Registration successful",
            "user": {
                "user_id": user_id,
                "name": name,
                "email": email,
                "role": "Employee"
            }
        }), 201

    except Error as e:

        connection.rollback()

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:
        close_db(cursor, connection)


# ============================================================
# LOGIN
# ============================================================

@app.route("/login", methods=["POST"])
def login():

    data = request.get_json(silent=True) or {}

    email = str(data.get("email", "")).strip().lower()
    password = str(data.get("password", ""))

    if not email or not password:
        return jsonify({
            "success": False,
            "message": "Email and password are required"
        }), 400

    connection = get_db_connection()

    if connection is None:
        return jsonify({
            "success": False,
            "message": "Database connection failed"
        }), 500

    cursor = None

    try:

        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            """
            SELECT
                user_id,
                name,
                email,
                password,
                role,
                created_at
            FROM users
            WHERE email = %s
            """,
            (email,)
        )

        user = cursor.fetchone()

        if user is None:
            return jsonify({
                "success": False,
                "message": "Invalid email or password"
            }), 401

        try:
            password_correct = check_password_hash(
                user["password"],
                password
            )
        except Exception:
            password_correct = False

        if not password_correct:
            return jsonify({
                "success": False,
                "message": "Invalid email or password"
            }), 401

        return jsonify({
            "success": True,
            "message": "Login successful",
            "user": {
                "user_id": user["user_id"],
                "name": user["name"],
                "email": user["email"],
                "role": user["role"],
                "created_at": convert_value(user["created_at"])
            }
        })

    except Error as e:

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:
        close_db(cursor, connection)


# ============================================================
# USERS
# ============================================================

@app.route("/users", methods=["GET"])
def get_users():

    connection = get_db_connection()

    if connection is None:
        return jsonify({
            "success": False,
            "message": "Database connection failed"
        }), 500

    cursor = None

    try:

        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            """
            SELECT
                user_id,
                name,
                email,
                role,
                created_at
            FROM users
            ORDER BY user_id DESC
            """
        )

        users = cursor.fetchall()

        for user in users:
            user["created_at"] = convert_value(
                user["created_at"]
            )

        return jsonify({
            "success": True,
            "users": users
        })

    except Error as e:

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:
        close_db(cursor, connection)


@app.route("/users/<int:user_id>", methods=["GET"])
def get_user(user_id):

    connection = get_db_connection()

    if connection is None:
        return jsonify({
            "success": False,
            "message": "Database connection failed"
        }), 500

    cursor = None

    try:

        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            """
            SELECT
                user_id,
                name,
                email,
                role,
                created_at
            FROM users
            WHERE user_id = %s
            """,
            (user_id,)
        )

        user = cursor.fetchone()

        if user is None:
            return jsonify({
                "success": False,
                "message": "User not found"
            }), 404

        user["created_at"] = convert_value(
            user["created_at"]
        )

        return jsonify({
            "success": True,
            "user": user
        })

    except Error as e:

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:
        close_db(cursor, connection)


# ============================================================
# TEAMS - GET
# ============================================================

@app.route("/teams", methods=["GET"])
def get_teams():

    connection = get_db_connection()

    if connection is None:
        return jsonify({
            "success": False,
            "message": "Database connection failed"
        }), 500

    cursor = None

    try:

        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            """
            SELECT
                team_id,
                team_name,
                description,
                created_by,
                created_at
            FROM teams
            ORDER BY team_id DESC
            """
        )

        teams = cursor.fetchall()

        for team in teams:
            team["created_at"] = convert_value(
                team["created_at"]
            )

        return jsonify({
            "success": True,
            "teams": teams
        })

    except Error as e:

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:
        close_db(cursor, connection)


# ============================================================
# TEAMS - CREATE
# ============================================================

@app.route("/teams", methods=["POST"])
def create_team():

    data = request.get_json(silent=True) or {}

    team_name = str(
        data.get("team_name", "")
    ).strip()

    description = str(
        data.get("description", "")
    ).strip()

    created_by = data.get("created_by")

    if not team_name:
        return jsonify({
            "success": False,
            "message": "Team name is required"
        }), 400

    if not created_by:
        return jsonify({
            "success": False,
            "message": "created_by is required"
        }), 400

    connection = get_db_connection()

    if connection is None:
        return jsonify({
            "success": False,
            "message": "Database connection failed"
        }), 500

    cursor = None

    try:

        cursor = connection.cursor()

        cursor.execute(
            """
            SELECT user_id
            FROM users
            WHERE user_id = %s
            """,
            (created_by,)
        )

        creator = cursor.fetchone()

        if creator is None:
            return jsonify({
                "success": False,
                "message": "Invalid creator"
            }), 400

        cursor.execute(
            """
            INSERT INTO teams
            (
                team_name,
                description,
                created_by
            )
            VALUES
            (%s, %s, %s)
            """,
            (
                team_name,
                description,
                created_by
            )
        )

        connection.commit()

        team_id = cursor.lastrowid

        return jsonify({
            "success": True,
            "message": "Team created successfully",
            "team_id": team_id
        }), 201

    except Error as e:

        connection.rollback()

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:
        close_db(cursor, connection)


# ============================================================
# TEAM MEMBERS
# ============================================================

@app.route("/teams/<int:team_id>/members", methods=["GET"])
def get_team_members(team_id):

    connection = get_db_connection()

    if connection is None:
        return jsonify({
            "success": False,
            "message": "Database connection failed"
        }), 500

    cursor = None

    try:

        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            """
            SELECT
                u.user_id,
                u.name,
                u.email,
                u.role
            FROM team_members tm
            INNER JOIN users u
                ON tm.user_id = u.user_id
            WHERE tm.team_id = %s
            ORDER BY u.name
            """,
            (team_id,)
        )

        members = cursor.fetchall()

        return jsonify({
            "success": True,
            "members": members
        })

    except Error as e:

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:
        close_db(cursor, connection)


@app.route("/teams/<int:team_id>/members", methods=["POST"])
def add_team_member(team_id):

    data = request.get_json(silent=True) or {}

    user_id = data.get("user_id")

    if not user_id:
        return jsonify({
            "success": False,
            "message": "user_id is required"
        }), 400

    connection = get_db_connection()

    if connection is None:
        return jsonify({
            "success": False,
            "message": "Database connection failed"
        }), 500

    cursor = None

    try:

        cursor = connection.cursor()

        cursor.execute(
            """
            SELECT team_id
            FROM teams
            WHERE team_id = %s
            """,
            (team_id,)
        )

        if cursor.fetchone() is None:
            return jsonify({
                "success": False,
                "message": "Team not found"
            }), 404

        cursor.execute(
            """
            SELECT user_id
            FROM users
            WHERE user_id = %s
            """,
            (user_id,)
        )

        if cursor.fetchone() is None:
            return jsonify({
                "success": False,
                "message": "User not found"
            }), 404

        cursor.execute(
            """
            SELECT user_id
            FROM team_members
            WHERE team_id = %s
            AND user_id = %s
            """,
            (team_id, user_id)
        )

        if cursor.fetchone() is not None:
            return jsonify({
                "success": False,
                "message": "User is already a member"
            }), 409

        cursor.execute(
            """
            INSERT INTO team_members
            (team_id, user_id)
            VALUES (%s, %s)
            """,
            (team_id, user_id)
        )

        connection.commit()

        return jsonify({
            "success": True,
            "message": "Member added successfully"
        }), 201

    except Error as e:

        connection.rollback()

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:
        close_db(cursor, connection)


# ============================================================
# PROJECTS - GET
# ============================================================

@app.route("/projects", methods=["GET"])
def get_projects():

    connection = get_db_connection()

    if connection is None:
        return jsonify({
            "success": False,
            "message": "Database connection failed"
        }), 500

    cursor = None

    try:

        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            """
            SELECT
                p.project_id,
                p.project_name,
                p.description,
                p.team_id,
                t.team_name,
                p.status,
                p.priority,
                p.start_date,
                p.due_date,
                p.created_by,
                u.name AS creator_name,
                p.created_at
            FROM projects p
            LEFT JOIN teams t
                ON p.team_id = t.team_id
            LEFT JOIN users u
                ON p.created_by = u.user_id
            ORDER BY p.project_id DESC
            """
        )

        projects = cursor.fetchall()

        for project in projects:
            project["start_date"] = convert_value(
                project["start_date"]
            )

            project["due_date"] = convert_value(
                project["due_date"]
            )

            project["created_at"] = convert_value(
                project["created_at"]
            )

        return jsonify({
            "success": True,
            "projects": projects
        })

    except Error as e:

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:
        close_db(cursor, connection)


# ============================================================
# PROJECTS - CREATE
# ============================================================

@app.route("/projects", methods=["POST"])
def create_project():

    data = request.get_json(silent=True) or {}

    project_name = str(
        data.get("project_name", "")
    ).strip()

    description = str(
        data.get("description", "")
    ).strip()

    team_id = data.get("team_id")

    status = str(
        data.get("status", "Planning")
    ).strip()

    priority = str(
        data.get("priority", "Medium")
    ).strip()

    start_date = data.get("start_date")
    due_date = data.get("due_date")

    created_by = data.get("created_by")

    if not project_name:
        return jsonify({
            "success": False,
            "message": "Project name is required"
        }), 400

    if not team_id:
        return jsonify({
            "success": False,
            "message": "Team is required"
        }), 400

    if not created_by:
        return jsonify({
            "success": False,
            "message": "created_by is required"
        }), 400

    allowed_status = [
        "Planning",
        "In Progress",
        "Completed",
        "On Hold"
    ]

    allowed_priority = [
        "Low",
        "Medium",
        "High",
        "Critical"
    ]

    if status not in allowed_status:
        return jsonify({
            "success": False,
            "message": "Invalid status"
        }), 400

    if priority not in allowed_priority:
        return jsonify({
            "success": False,
            "message": "Invalid priority"
        }), 400

    connection = get_db_connection()

    if connection is None:
        return jsonify({
            "success": False,
            "message": "Database connection failed"
        }), 500

    cursor = None

    try:

        cursor = connection.cursor()

        # Check team
        cursor.execute(
            """
            SELECT team_id
            FROM teams
            WHERE team_id = %s
            """,
            (team_id,)
        )

        if cursor.fetchone() is None:
            return jsonify({
                "success": False,
                "message": "Selected team does not exist"
            }), 400

        # Check creator
        cursor.execute(
            """
            SELECT user_id
            FROM users
            WHERE user_id = %s
            """,
            (created_by,)
        )

        if cursor.fetchone() is None:
            return jsonify({
                "success": False,
                "message": "Invalid creator"
            }), 400

        cursor.execute(
            """
            INSERT INTO projects
            (
                project_name,
                description,
                team_id,
                status,
                priority,
                start_date,
                due_date,
                created_by
            )
            VALUES
            (%s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (
                project_name,
                description,
                team_id,
                status,
                priority,
                start_date if start_date else None,
                due_date if due_date else None,
                created_by
            )
        )

        connection.commit()

        project_id = cursor.lastrowid

        return jsonify({
            "success": True,
            "message": "Project created successfully",
            "project_id": project_id
        }), 201

    except Error as e:

        connection.rollback()

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:
        close_db(cursor, connection)


# ============================================================
# PROJECT MEMBERS
# ============================================================

@app.route("/projects/<int:project_id>/members", methods=["GET"])
def get_project_members(project_id):

    connection = get_db_connection()

    if connection is None:
        return jsonify({
            "success": False,
            "message": "Database connection failed"
        }), 500

    cursor = None

    try:

        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            """
            SELECT
                u.user_id,
                u.name,
                u.email,
                u.role
            FROM project_members pm
            INNER JOIN users u
                ON pm.user_id = u.user_id
            WHERE pm.project_id = %s
            ORDER BY u.name
            """,
            (project_id,)
        )

        members = cursor.fetchall()

        return jsonify({
            "success": True,
            "members": members
        })

    except Error as e:

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:
        close_db(cursor, connection)


# ============================================================
# TASKS - GET
# ============================================================

@app.route("/tasks", methods=["GET"])
def get_tasks():

    connection = get_db_connection()

    if connection is None:
        return jsonify({
            "success": False,
            "message": "Database connection failed"
        }), 500

    cursor = None

    try:

        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            """
            SELECT
                t.task_id,
                t.project_id,
                p.project_name,
                t.title,
                t.description,
                t.assigned_to,
                a.name AS assigned_name,
                t.created_by,
                c.name AS creator_name,
                t.priority,
                t.status,
                t.due_date,
                t.completed_at,
                t.created_at
            FROM tasks t
            LEFT JOIN projects p
                ON t.project_id = p.project_id
            LEFT JOIN users a
                ON t.assigned_to = a.user_id
            LEFT JOIN users c
                ON t.created_by = c.user_id
            ORDER BY t.task_id DESC
            """
        )

        tasks = cursor.fetchall()

        for task in tasks:

            task["due_date"] = convert_value(
                task["due_date"]
            )

            task["completed_at"] = convert_value(
                task["completed_at"]
            )

            task["created_at"] = convert_value(
                task["created_at"]
            )

        return jsonify({
            "success": True,
            "tasks": tasks
        })

    except Error as e:

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:
        close_db(cursor, connection)


# ============================================================
# TASKS - CREATE
# ============================================================

@app.route("/tasks", methods=["POST"])
def create_task():

    data = request.get_json(silent=True) or {}

    project_id = data.get("project_id")
    title = str(data.get("title", "")).strip()
    description = str(data.get("description", "")).strip()

    assigned_to = data.get("assigned_to")
    created_by = data.get("created_by")

    priority = str(
        data.get("priority", "Medium")
    ).strip()

    status = str(
        data.get("status", "Pending")
    ).strip()

    due_date = data.get("due_date")

    if not title:
        return jsonify({
            "success": False,
            "message": "Task title is required"
        }), 400

    if not project_id:
        return jsonify({
            "success": False,
            "message": "Project is required"
        }), 400

    if not created_by:
        return jsonify({
            "success": False,
            "message": "created_by is required"
        }), 400

    connection = get_db_connection()

    if connection is None:
        return jsonify({
            "success": False,
            "message": "Database connection failed"
        }), 500

    cursor = None

    try:

        cursor = connection.cursor()

        cursor.execute(
            """
            SELECT project_id
            FROM projects
            WHERE project_id = %s
            """,
            (project_id,)
        )

        if cursor.fetchone() is None:
            return jsonify({
                "success": False,
                "message": "Project not found"
            }), 404

        cursor.execute(
            """
            INSERT INTO tasks
            (
                project_id,
                title,
                description,
                assigned_to,
                created_by,
                priority,
                status,
                due_date
            )
            VALUES
            (%s,%s,%s,%s,%s,%s,%s,%s)
            """,
            (
                project_id,
                title,
                description,
                assigned_to if assigned_to else None,
                created_by,
                priority,
                status,
                due_date if due_date else None
            )
        )

        connection.commit()

        return jsonify({
            "success": True,
            "message": "Task created successfully",
            "task_id": cursor.lastrowid
        }), 201

    except Error as e:

        connection.rollback()

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:
        close_db(cursor, connection)


# ============================================================
# TASKS - UPDATE
# ============================================================

@app.route("/tasks/<int:task_id>", methods=["PUT"])
def update_task(task_id):

    data = request.get_json(silent=True) or {}

    status = data.get("status")
    priority = data.get("priority")

    connection = get_db_connection()

    if connection is None:
        return jsonify({
            "success": False,
            "message": "Database connection failed"
        }), 500

    cursor = None

    try:

        cursor = connection.cursor()

        if status is not None:

            if status == "Completed":

                cursor.execute(
                    """
                    UPDATE tasks
                    SET status = %s,
                        completed_at = CURRENT_TIMESTAMP
                    WHERE task_id = %s
                    """,
                    (status, task_id)
                )

            else:

                cursor.execute(
                    """
                    UPDATE tasks
                    SET status = %s,
                        completed_at = NULL
                    WHERE task_id = %s
                    """,
                    (status, task_id)
                )

        if priority is not None:

            cursor.execute(
                """
                UPDATE tasks
                SET priority = %s
                WHERE task_id = %s
                """,
                (priority, task_id)
            )

        connection.commit()

        return jsonify({
            "success": True,
            "message": "Task updated successfully"
        })

    except Error as e:

        connection.rollback()

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:
        close_db(cursor, connection)


# ============================================================
# MEETINGS - GET
# ============================================================

@app.route("/meetings", methods=["GET"])
def get_meetings():

    connection = get_db_connection()

    if connection is None:
        return jsonify({
            "success": False,
            "message": "Database connection failed"
        }), 500

    cursor = None

    try:

        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            """
            SELECT
                m.meeting_id,
                m.title,
                m.description,
                m.team_id,
                t.team_name,
                m.project_id,
                p.project_name,
                m.organizer_id,
                u.name AS organizer_name,
                m.start_time,
                m.end_time,
                m.meeting_link,
                m.status,
                m.created_at
            FROM meetings m
            LEFT JOIN teams t
                ON m.team_id = t.team_id
            LEFT JOIN projects p
                ON m.project_id = p.project_id
            LEFT JOIN users u
                ON m.organizer_id = u.user_id
            ORDER BY m.start_time DESC
            """
        )

        meetings = cursor.fetchall()

        for meeting in meetings:

            meeting["start_time"] = convert_value(
                meeting["start_time"]
            )

            meeting["end_time"] = convert_value(
                meeting["end_time"]
            )

            meeting["created_at"] = convert_value(
                meeting["created_at"]
            )

        return jsonify({
            "success": True,
            "meetings": meetings
        })

    except Error as e:

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:
        close_db(cursor, connection)


# ============================================================
# MEETINGS - CREATE
# ============================================================

@app.route("/meetings", methods=["POST"])
def create_meeting():

    data = request.get_json(silent=True) or {}

    title = str(
        data.get("title", "")
    ).strip()

    description = str(
        data.get("description", "")
    ).strip()

    team_id = data.get("team_id")
    project_id = data.get("project_id")
    organizer_id = data.get("organizer_id")

    start_time = data.get("start_time")
    end_time = data.get("end_time")

    meeting_link = str(
        data.get("meeting_link", "")
    ).strip()

    status = str(
        data.get("status", "Scheduled")
    ).strip()

    if not title:
        return jsonify({
            "success": False,
            "message": "Meeting title is required"
        }), 400

    if not organizer_id:
        return jsonify({
            "success": False,
            "message": "organizer_id is required"
        }), 400

    if not start_time:
        return jsonify({
            "success": False,
            "message": "Start time is required"
        }), 400

    connection = get_db_connection()

    if connection is None:
        return jsonify({
            "success": False,
            "message": "Database connection failed"
        }), 500

    cursor = None

    try:

        cursor = connection.cursor()

        cursor.execute(
            """
            INSERT INTO meetings
            (
                title,
                description,
                team_id,
                project_id,
                organizer_id,
                start_time,
                end_time,
                meeting_link,
                status
            )
            VALUES
            (%s,%s,%s,%s,%s,%s,%s,%s,%s)
            """,
            (
                title,
                description,
                team_id if team_id else None,
                project_id if project_id else None,
                organizer_id,
                start_time,
                end_time if end_time else None,
                meeting_link if meeting_link else None,
                status
            )
        )

        connection.commit()

        return jsonify({
            "success": True,
            "message": "Meeting created successfully",
            "meeting_id": cursor.lastrowid
        }), 201

    except Error as e:

        connection.rollback()

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:
        close_db(cursor, connection)


# ============================================================
# CHAT ROOMS - GET
# ============================================================

@app.route("/chat-rooms", methods=["GET"])
def get_chat_rooms():

    connection = get_db_connection()

    if connection is None:
        return jsonify({
            "success": False,
            "message": "Database connection failed"
        }), 500

    cursor = None

    try:

        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            """
            SELECT
                room_id,
                name,
                room_type,
                team_id,
                project_id,
                meeting_id,
                created_by,
                created_at
            FROM chat_rooms
            ORDER BY room_id DESC
            """
        )

        rooms = cursor.fetchall()

        for room in rooms:
            room["created_at"] = convert_value(
                room["created_at"]
            )

        return jsonify({
            "success": True,
            "rooms": rooms
        })

    except Error as e:

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:
        close_db(cursor, connection)


# ============================================================
# CHAT ROOM - CREATE
# ============================================================

@app.route("/chat-rooms", methods=["POST"])
def create_chat_room():

    data = request.get_json(silent=True) or {}

    name = str(
        data.get("name", "")
    ).strip()

    room_type = str(
        data.get("room_type", "Team")
    ).strip()

    team_id = data.get("team_id")
    project_id = data.get("project_id")
    meeting_id = data.get("meeting_id")
    created_by = data.get("created_by")

    if not name:
        return jsonify({
            "success": False,
            "message": "Chat room name is required"
        }), 400

    if not created_by:
        return jsonify({
            "success": False,
            "message": "created_by is required"
        }), 400

    connection = get_db_connection()

    if connection is None:
        return jsonify({
            "success": False,
            "message": "Database connection failed"
        }), 500

    cursor = None

    try:

        cursor = connection.cursor()

        cursor.execute(
            """
            INSERT INTO chat_rooms
            (
                name,
                room_type,
                team_id,
                project_id,
                meeting_id,
                created_by
            )
            VALUES
            (%s,%s,%s,%s,%s,%s)
            """,
            (
                name,
                room_type,
                team_id if team_id else None,
                project_id if project_id else None,
                meeting_id if meeting_id else None,
                created_by
            )
        )

        connection.commit()

        return jsonify({
            "success": True,
            "message": "Chat room created successfully",
            "room_id": cursor.lastrowid
        }), 201

    except Error as e:

        connection.rollback()

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:
        close_db(cursor, connection)


# ============================================================
# CHAT MESSAGES - GET
# ============================================================

@app.route("/chat-rooms/<int:room_id>/messages", methods=["GET"])
def get_messages(room_id):

    connection = get_db_connection()

    if connection is None:
        return jsonify({
            "success": False,
            "message": "Database connection failed"
        }), 500

    cursor = None

    try:

        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            """
            SELECT
                m.message_id,
                m.room_id,
                m.sender_id,
                u.name AS sender_name,
                m.message_text,
                m.attachment_url,
                m.attachment_name,
                m.sent_at,
                m.edited_at,
                m.is_deleted
            FROM messages m
            LEFT JOIN users u
                ON m.sender_id = u.user_id
            WHERE m.room_id = %s
            ORDER BY m.message_id ASC
            """,
            (room_id,)
        )

        messages = cursor.fetchall()

        for message in messages:

            message["sent_at"] = convert_value(
                message["sent_at"]
            )

            message["edited_at"] = convert_value(
                message["edited_at"]
            )

        return jsonify({
            "success": True,
            "messages": messages
        })

    except Error as e:

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:
        close_db(cursor, connection)


# ============================================================
# SEND MESSAGE
# ============================================================

@app.route("/chat-rooms/<int:room_id>/messages", methods=["POST"])
def send_message(room_id):

    data = request.get_json(silent=True) or {}

    sender_id = data.get("sender_id")

    message_text = str(
        data.get("message_text", "")
    ).strip()

    attachment_url = data.get("attachment_url")
    attachment_name = data.get("attachment_name")

    if not sender_id:
        return jsonify({
            "success": False,
            "message": "sender_id is required"
        }), 400

    if not message_text and not attachment_url:
        return jsonify({
            "success": False,
            "message": "Message cannot be empty"
        }), 400

    connection = get_db_connection()

    if connection is None:
        return jsonify({
            "success": False,
            "message": "Database connection failed"
        }), 500

    cursor = None

    try:

        cursor = connection.cursor()

        cursor.execute(
            """
            INSERT INTO messages
            (
                room_id,
                sender_id,
                message_text,
                attachment_url,
                attachment_name
            )
            VALUES
            (%s,%s,%s,%s,%s)
            """,
            (
                room_id,
                sender_id,
                message_text,
                attachment_url,
                attachment_name
            )
        )

        connection.commit()

        return jsonify({
            "success": True,
            "message": "Message sent successfully",
            "message_id": cursor.lastrowid
        }), 201

    except Error as e:

        connection.rollback()

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:
        close_db(cursor, connection)


# ============================================================
# NOTIFICATIONS - GET
# ============================================================

@app.route("/notifications/<int:user_id>", methods=["GET"])
def get_notifications(user_id):

    connection = get_db_connection()

    if connection is None:
        return jsonify({
            "success": False,
            "message": "Database connection failed"
        }), 500

    cursor = None

    try:

        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            """
            SELECT
                notification_id,
                user_id,
                type,
                title,
                message,
                related_type,
                related_id,
                is_read,
                created_at
            FROM notifications
            WHERE user_id = %s
            ORDER BY notification_id DESC
            """,
            (user_id,)
        )

        notifications = cursor.fetchall()

        for notification in notifications:
            notification["created_at"] = convert_value(
                notification["created_at"]
            )

        return jsonify({
            "success": True,
            "notifications": notifications
        })

    except Error as e:

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:
        close_db(cursor, connection)


# ============================================================
# CREATE NOTIFICATION
# ============================================================

@app.route("/notifications", methods=["POST"])
def create_notification():

    data = request.get_json(silent=True) or {}

    user_id = data.get("user_id")

    notification_type = str(
        data.get("type", "General")
    ).strip()

    title = str(
        data.get("title", "")
    ).strip()

    message = str(
        data.get("message", "")
    ).strip()

    related_type = data.get("related_type")
    related_id = data.get("related_id")

    if not user_id:
        return jsonify({
            "success": False,
            "message": "user_id is required"
        }), 400

    if not title:
        return jsonify({
            "success": False,
            "message": "title is required"
        }), 400

    if not message:
        return jsonify({
            "success": False,
            "message": "message is required"
        }), 400

    connection = get_db_connection()

    if connection is None:
        return jsonify({
            "success": False,
            "message": "Database connection failed"
        }), 500

    cursor = None

    try:

        cursor = connection.cursor()

        cursor.execute(
            """
            INSERT INTO notifications
            (
                user_id,
                type,
                title,
                message,
                related_type,
                related_id
            )
            VALUES
            (%s,%s,%s,%s,%s,%s)
            """,
            (
                user_id,
                notification_type,
                title,
                message,
                related_type,
                related_id
            )
        )

        connection.commit()

        return jsonify({
            "success": True,
            "message": "Notification created successfully",
            "notification_id": cursor.lastrowid
        }), 201

    except Error as e:

        connection.rollback()

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:
        close_db(cursor, connection)


# ============================================================
# MARK NOTIFICATION AS READ
# ============================================================

@app.route(
    "/notifications/<int:notification_id>/read",
    methods=["PUT"]
)
def mark_notification_read(notification_id):

    connection = get_db_connection()

    if connection is None:
        return jsonify({
            "success": False,
            "message": "Database connection failed"
        }), 500

    cursor = None

    try:

        cursor = connection.cursor()

        cursor.execute(
            """
            UPDATE notifications
            SET is_read = 1
            WHERE notification_id = %s
            """,
            (notification_id,)
        )

        connection.commit()

        return jsonify({
            "success": True,
            "message": "Notification marked as read"
        })

    except Error as e:

        connection.rollback()

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:
        close_db(cursor, connection)


# ============================================================
# SETTINGS - GET
# ============================================================

@app.route("/settings/<int:user_id>", methods=["GET"])
def get_settings(user_id):

    connection = get_db_connection()

    if connection is None:
        return jsonify({
            "success": False,
            "message": "Database connection failed"
        }), 500

    cursor = None

    try:

        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            """
            SELECT
                user_id,
                notifications_enabled,
                sound_enabled,
                dark_mode
            FROM user_settings
            WHERE user_id = %s
            """,
            (user_id,)
        )

        settings = cursor.fetchone()

        if settings is None:
            return jsonify({
                "success": True,
                "settings": {
                    "user_id": user_id,
                    "notifications_enabled": 1,
                    "sound_enabled": 1,
                    "dark_mode": 0
                }
            })

        return jsonify({
            "success": True,
            "settings": settings
        })

    except Error as e:

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:
        close_db(cursor, connection)


# ============================================================
# SETTINGS - UPDATE
# ============================================================

@app.route("/settings/<int:user_id>", methods=["PUT"])
def update_settings(user_id):

    data = request.get_json(silent=True) or {}

    notifications_enabled = int(
        bool(data.get("notifications_enabled", True))
    )

    sound_enabled = int(
        bool(data.get("sound_enabled", True))
    )

    dark_mode = int(
        bool(data.get("dark_mode", False))
    )

    connection = get_db_connection()

    if connection is None:
        return jsonify({
            "success": False,
            "message": "Database connection failed"
        }), 500

    cursor = None

    try:

        cursor = connection.cursor()

        cursor.execute(
            """
            INSERT INTO user_settings
            (
                user_id,
                notifications_enabled,
                sound_enabled,
                dark_mode
            )
            VALUES
            (%s,%s,%s,%s)
            ON DUPLICATE KEY UPDATE
                notifications_enabled =
                    VALUES(notifications_enabled),
                sound_enabled =
                    VALUES(sound_enabled),
                dark_mode =
                    VALUES(dark_mode)
            """,
            (
                user_id,
                notifications_enabled,
                sound_enabled,
                dark_mode
            )
        )

        connection.commit()

        return jsonify({
            "success": True,
            "message": "Settings updated successfully"
        })

    except Error as e:

        connection.rollback()

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:
        close_db(cursor, connection)


# ============================================================
# START SERVER
# ============================================================

if __name__ == "__main__":

    print()
    print("==============================================")
    print("       TEAM APP BACKEND SERVER")
    print("==============================================")
    print("Database : team_app_db")
    print("Server   : http://0.0.0.0:5000")
    print("Android  : http://192.168.1.43:5000")
    print("==============================================")
    print()

    app.run(
        host="0.0.0.0",
        port=5000,
        debug=True
    )