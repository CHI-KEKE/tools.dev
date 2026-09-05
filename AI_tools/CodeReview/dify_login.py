def encode_base64(input_string: str) -> str:
    encoded_bytes = base64.b64encode(input_string.encode("utf-8"))
    return encoded_bytes.decode("utf-8")

DIFY_HOST_Prod = CONFIG["Dify"]["Host"]["Prod"]
DIFY_HOST_QA = CONFIG["Dify"]["Host"]["QA"]
DIFY_EMAIL = CONFIG["Dify"]["Email"]
DIFY_PASSWORD = SECRETS.get("Dify_Password", "")
DIFY_PASSWORD_ENCODED = encode_base64(DIFY_PASSWORD)

def _extract_cookie_value(session: requests.Session, suffix: str) -> Optional[str]:
    for name, value in session.cookies.items():
        if name.endswith(suffix):
            return value
    return None

def login(dify_host: str, dify_email: str, dify_password: str) -> requests.Session:
    session = requests.Session()

    url = f"{dify_host}/login"

    payload = {
        "email": dify_email,
        "password": dify_password
    }

    response = session.post(url, json=payload, timeout=30)
    response.raise_for_status()

    access_token = _extract_cookie_value(session, "access_token")
    csrf_token = _extract_cookie_value(session, "csrf_token")

    if not access_token or not csrf_token:
        raise ValueError("Login failed: access_token or csrf_token not found in cookies")

    session.headers.update({
        "Authorization": f"Bearer {access_token}",
        "X-CSRF-Token": csrf_token
    })

    return session

def list_apps(dify_host: str, session: requests.Session) -> list[dict]:
    apps: list[dict] = []
    apps_total = 0
    page = 1

    while True:
        url = f"{dify_host}/apps?page={page}&limit=100"
        response = session.get(url, timeout=30)
        response.raise_for_status()
        result = response.json()

        if apps_total == 0:
            apps_total = result.get("total")

        apps.extend(result.get("data"))

        if len(apps) == apps_total:
            break

        page += 1

    return apps