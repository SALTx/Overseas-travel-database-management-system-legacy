import pymysql
import random
from datetime import date, timedelta

def create_conn():
    conn = pymysql.connect(host='localhost',
                           user='root',
                           password='',
                           database='overseasProgramDB')
    return conn

global_date = date(2023, 1, 1)  # This date will be incremented for each program

def random_date(num_days):
    """Generate a random date within num_days after the global date."""
    global global_date
    random_days = random.randrange(num_days)
    result_date = global_date + timedelta(days=random_days)
    global_date = result_date
    return result_date

def generate_internship_programs(num_programs, conn):
    # Fetch country names from the 'countries' table where aciCountry = 'A'
    with conn.cursor() as cursor:
        cursor.execute("SELECT countryName FROM countries WHERE aciCountry = 'A'")
        country_names = [row[0] for row in cursor.fetchall()]
    
    programs = []
    overseas_partner_types = ['Company', 'Institution', 'Others']
    
    for _ in range(num_programs):
        programID = 'PROG' + str(random.randint(1, 99999)).zfill(5)
        programName = 'Program ' + programID
        programType = 'Overseas internship program'
        startDate = random_date(7)  # Start dates are up to a week after the global date
        endDate = random_date(14)  # End dates are up to two weeks after the global date
        ESTdate = None
        countryName = random.choice(country_names)
        city = 'City ' + str(random.randint(1, 100))
        partnerName = 'Partner ' + str(random.randint(1, 100))
        overseasPartnerType = random.choice(overseas_partner_types)
        tripLeaders = None
        EstNumStudents = None
        approved = 'Yes'
        programs.append((programID, programName, programType, startDate, endDate, ESTdate, countryName, city, partnerName, overseasPartnerType, tripLeaders, EstNumStudents, approved))
    
    return programs

def insert_into_table(table_name, data, conn):
    with conn.cursor() as cursor:
        for row in data:
            placeholders = ', '.join(['%s'] * len(row))
            query = f"INSERT INTO {table_name} (programID, programName, programType, startDate, endDate, ESTdate, countryName, city, partnerName, overseasPartnerType, tripLeaders, EstNumStudents, approved) VALUES ({placeholders})"
            cursor.execute(query, row)
    conn.commit()

conn = create_conn()

# Generate dummy data for 20 overseas internship programs
programs = generate_internship_programs(20, conn)

# Insert the dummy data into the 'overseasPrograms' table
insert_into_table('overseasPrograms', programs, conn)

conn.close()  # Don't forget to close the connection