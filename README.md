# db2022-inl
Assignment for course in Database development

## Entity Relationship Diagram

```mermaid
erDiagram
    Student ||--o{ StudentSchool : enrolls
    School ||--o{ StudentSchool : accepts
    Student ||--o{ StudentHobby : has
    Hobby ||--o{ StudentHobby : involves
    Student ||--o{ Phone : has
    Student }|--o| Grade : has
       

    Hobby {
    	int Hobbyid
	string Name
    }

    Phone {
    	int PhoneId
	int StudentId
	string Type
	string Number
    }

    StudentHobby {
	  int StudentId
	  int HobbyId 
    }

    StudentSchool {
        int StudentId
        int SchoolId
    }

    Student {
        int StudentId
        string FirstName
        string LastName
	int GradeId
    }

    School {
        int SchoolId
        string Name
        string City
    }

    Grade {
        int GradeId
        string Name
    }
```

## Cardinality

![Cardinality](cardinality-1.png)
