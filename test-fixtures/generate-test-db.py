"""
This script manages the process of creating and modifying a database in the context of a simulated iOS environment.
It interacts with a SQLite database, and takes user input for the number of history and bookmark records to create,
and for naming the new database file. The script uses the `websites.csv` file located in the same directory to
generate records and insert them into the database. The `websites.csv` file contains the top 1000 work-safe websites
and is used by default.

If you want to add your own custom websites, then create a csv file in this directory with those websites. You can use
the `websites.csv` file as a template. You'll just need to change the constant `CSV_FILE` to the name of the csv file you
want to use.

PLEASE NOTE:
In order for this script to work, you must have an iOS Simulator instance open with a build of firefox-ios installed.
This script looks for a booted Simulator device with an app loaded whose BUNDLE_ID is 'org.mozilla.ios.Fennec' and
assumes you want to copy the 'places.db' database.

This also assumes you ONLY HAVE ONE BOOTED SIMULATOR INSTANCE open as it will only return the first instance it finds.

The script currently doesn't support modifications to:
    - autofill.db
    - browser.db
    - ReadingList.db
though it may in the future.
"""

import csv
import sqlite3
import random
import string
import time
import shutil
import os
import re
import subprocess
import logging

BUNDLE_ID = 'org.mozilla.ios.Fennec'
APP_GROUP_ID = 'group.org.mozilla.ios.Fennec'
CSV_FILE = 'websites.csv'

def _init_logging():
    logging.basicConfig(
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        level=logging.ERROR,
    )

def get_db_path(bundle_id, app_group):
    """
    Returns the path to the places.db file in the profile.profile directory of the app
    using the specified bundle_id and app_group.
    """
    device_id = get_device_id()
    app_group_id = get_app_group_id(bundle_id)
    
    # Now we search for the app ID by looking at installed apps
    app_container_path = os.path.expanduser(f'~/Library/Developer/CoreSimulator/Devices/{device_id}/data/Containers/Shared/AppGroup/{app_group_id}')

    # Construct the path to the places.db file in the profile.profile directory
    return os.path.join(app_container_path, 'profile.profile', 'places.db')
    
def get_device_id():
    """
    Returns the ID of the booted device in the simulator environment.
    """
    result = subprocess.run(['xcrun', 'simctl', 'list', 'devices'], capture_output=True, text=True)
    lines = result.stdout.splitlines()
    
    device_id = None
    for line in lines:
        if '(Booted)' in line:
            match = re.search(r'\((.*?)\)', line)
            if match:
                device_id = match.group(1)
                break
    if not device_id:
        raise Exception('No booted simulator found! Please launch an iOS Simulator device and try again.')
    return device_id

def get_app_group_id(bundle_id):
    """
    Returns the app group ID for the given bundle ID.
    """
    app_group_command = ['xcrun', 'simctl', 'get_app_container', 'booted', bundle_id, 'groups']
    result = subprocess.run(app_group_command, capture_output=True, text=True)
    app_group_container_path = result.stdout.strip()

    # Extract the app_group_id from the returned path
    app_group_id = os.path.basename(app_group_container_path)
    if not app_group_id:
        raise Exception(f'Could not find app group ID for bundle ID {bundle_id}. Please verify you have the app installed and try again.')
    
    return app_group_id

# GUID is a required field for each record and needs to be created
def generate_guid():
    return ''.join(random.choice(string.ascii_lowercase + string.ascii_uppercase + string.digits) for _ in range(12))

def insert_into_moz_places(cursor, url, title, last_visit_date_local, guid):
    """
    Inserts a record into the moz_places table.

    Args:
    cursor (sqlite3.Cursor): Database cursor object.
    url (str): The URL to be inserted.
    title (str): The title to be inserted.
    last_visit_date_local (int): The last visit date in local time.
    guid (str): The GUID for the record.
    """
    cursor.execute(
        "INSERT INTO moz_places(url, title, last_visit_date_local, guid) VALUES (?, ?, ?, ?)",
        (url, title, last_visit_date_local, guid)
    )

def insert_into_moz_bookmarks(cursor, fk, bookmarks_type, parent, position, title, date_added, last_modified, guid):
    """
    Inserts a record into the moz_bookmarks table.

    Args:
    cursor (sqlite3.Cursor): Database cursor object.
    fk (int): The foreign key for the record referencing the moz_places table.
    bookmarks_type (int): The type of bookmark.
    parent (int): The parent record id.
    position (int): The position of the bookmark for display in Bookmarks.
    title (str): The title of the bookmark.
    date_added (int): The date the bookmark was added.
    last_modified (int): The last date the bookmark was modified.
    guid (str): The GUID for the record.
    """
    cursor.execute(
        "INSERT INTO moz_bookmarks(fk, type, parent, position, title, dateAdded, lastModified, guid) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        (fk, bookmarks_type, parent, position, title, date_added, last_modified, guid)
    )

def insert_into_moz_historyvisits(cursor, is_local, place_id, visit_date, visit_type):
    """
    Inserts a record into the moz_historyvisits table.

    Args:
    cursor (sqlite3.Cursor): Database cursor object.
    is_local (int): Indicator if the visit is local or not (1 for local).
    place_id (int): The place ID for the record.
    visit_date (int): The visit date.
    visit_type (int): The type of visit.
    """
    cursor.execute(
        "INSERT INTO moz_historyvisits(is_local, place_id, visit_date, visit_type) VALUES (?, ?, ?, ?)",
        (is_local, place_id, visit_date, visit_type)
    )

def create_and_clean_database(db_new_name, db_path):
    """
    Creates the new database, inserts records into it, and then cleans up.

    Args:
    db_new_name (str): The new name of the created database.
    db_path (str): The path to the new database.
    """
    # Get the absolute path of the directory that the script is located in
    script_dir = os.path.dirname(os.path.abspath(__file__))

    # Create the full path for the new database
    db_new_path = os.path.join(script_dir, db_new_name)

    try:
        # Copy the database file
        shutil.copyfile(db_path, db_new_path)
    except Exception as e:
        logging.error(f"Error occurred while copying the database: {str(e)}")

    # Connect to the new database file
    db_connection = sqlite3.connect(db_new_path)
    db_cursor = db_connection.cursor()

    # Make sure tables are empty before inserting new records
    db_cursor.execute("DELETE FROM moz_historyvisits")
    db_cursor.execute("DELETE FROM moz_bookmarks WHERE parent = 5")
    db_cursor.execute("DELETE FROM moz_places")

    db_connection.commit()

    return db_connection, db_cursor


def read_websites_and_insert_records(db_connection, db_cursor, history_count, bookmark_count):
    """
    Read URLs from websites.csv and insert records into the database.

    This function will insert records into `moz_places`, `moz_historyvisits`, and
    `moz_bookmarks` tables. It will stop inserting once the provided counts for history
    and bookmarks records have been reached.

    Args:
    db_connection (sqlite3.Connect): Connection instance to database.
    db_cursor (sqlite3.Cursor): Database cursor to execute SQL commands.
    history_count (int): The number of history records to be created.
    bookmark_count (int): The number of bookmark records to be created.

    """
    # Get the absolute path of the directory that the script is located in
    script_dir = os.path.dirname(os.path.abspath(__file__))

    # Construct the path to the websites.csv file
    websites_file_path = os.path.join(script_dir, CSV_FILE)

    # Read in websites.csv
    with open(websites_file_path, newline='') as csvfile:
        reader = csv.reader(csvfile)
        place_id = 1
        bookmarks_position = 0

        while history_count > 0 or bookmark_count > 0:
            for row in reader:
                if history_count <= 0 and bookmark_count <= 0:
                    break

                current_time_milliseconds = int(time.time() * 1000)
                guid = generate_guid()
                url = f"https://{row[1]}"
                title = row[1]

                insert_into_moz_places(db_cursor, url, title, current_time_milliseconds, guid)

                if history_count > 0:
                    insert_into_moz_historyvisits(db_cursor, 1, place_id, current_time_milliseconds, 1)
                    history_count -= 1

                if bookmark_count > 0:
                    insert_into_moz_bookmarks(db_cursor, place_id, 1, 5, bookmarks_position, title, current_time_milliseconds, current_time_milliseconds, guid)
                    bookmark_count -= 1

                place_id += 1
                bookmarks_position += 1
                
            csvfile.seek(0)  # When adding over 1000 records, we need to go back to the start of the file

        # Commit the changes outside the loop
        db_connection.commit()


def main():
    """
    This script does the following:
    1. Asks the user for the number of history and bookmark records to create.
    2. Asks the user to name the new database file (without the .db extension).
    3. Obtains the path of the current places.db file in the simulator's app directory.
    4. Copies the existing places.db to a new database file in the script's directory with the user-given name.
    5. Connects to the new database.
    6. Deletes all existing records from the moz_historyvisits, moz_bookmarks, and moz_places tables in the database.
    7. Opens a 'websites.csv' file that contains a list of the top 1000 websites.
    8. Inserts records into the moz_places, moz_historyvisits, and moz_bookmarks tables using data from the 'websites.csv'.
    9. Closes the connection to the database after all operations are done.
    """

    _init_logging()

    db_connection = None  # Initialize db_connection here
    try:
        # User inputs for number of records to create for history and bookmarks
        history_count = int(input("Enter the number of records to create for history: "))
        bookmark_count = int(input("Enter the number of records to create for bookmarks: "))
        db_new_name = input("Enter the name of the new database file (without the .db extension): ").strip()

        # If the user didn't provide a new name, or if the name has forbidden characters, use a default name
        if not db_new_name or not all(char.isalnum() or char in '._-' for char in db_new_name):
            db_new_name = 'places.copy.db'

        # Append .db to the database name
        db_new_name += '.db'

        # Get the path to the places.db file
        db_path = get_db_path(BUNDLE_ID, APP_GROUP_ID)

        # Create a new database and clean it
        db_connection, db_cursor = create_and_clean_database(db_new_name, db_path)

        # Read websites from CSV and insert records
        read_websites_and_insert_records(db_connection, db_cursor, history_count, bookmark_count)

    except sqlite3.Error as e:
        logging.error(f"SQLite error occurred: {str(e)}")
    except Exception as e:
        logging.error(f"Error occurred: {str(e)}")
    finally:
        # Script errors cause db_connection to be lost, throwing UnboundLocalError
        # check if db_connection has been lost already before trying to close connection
        if db_connection is not None:
            db_connection.close()

if __name__ == "__main__":
    main()
