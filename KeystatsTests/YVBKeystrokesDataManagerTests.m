//
//  YVBKeystrokesDataManagerTests.m
//  Keystats
//
//  Created by Yoshiki Vázquez Baeza on 12/29/13.
//  Copyright (c) 2013 Yoshiki Vázquez Baeza. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "YVBKeystrokesDataManager.h"
#import "FMDatabase.h"

@interface YVBKeystrokesDataManagerTests : XCTestCase{

	NSString *temporaryDatabasePath;
	NSString *writableDatabasePath;
	NSString *writableDatabasePathSpecial;
}

@end

@implementation YVBKeystrokesDataManagerTests

- (void)setUp{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
	NSError *error=nil;

	// retrieve the filepath of the database that we are going to be using
	NSURL *testDatabase = [[NSBundle bundleForClass:[self class]] URLForResource:@"test-keystrokes"
																   withExtension:@""];
	
	temporaryDatabasePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"/test-keystrokes"];
	writableDatabasePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"/test-keystrokes-writable"];
	writableDatabasePathSpecial = [NSTemporaryDirectory() stringByAppendingPathComponent:@"/test-keystrokes-writable-special"];

	[[NSFileManager defaultManager]	copyItemAtPath:[testDatabase path]
											toPath:temporaryDatabasePath
											 error:&error];
	XCTAssertNil(error, @"Cannot copy readable database ... cannot continue");
	error = nil;

	[[NSFileManager defaultManager]	copyItemAtPath:[testDatabase path]
											toPath:writableDatabasePath
											 error:&error];
	XCTAssertNil(error, @"Cannot copy writable database ... cannot continue");

	[[NSFileManager defaultManager]	copyItemAtPath:[testDatabase path]
											toPath:writableDatabasePathSpecial
											 error:&error];
	XCTAssertNil(error, @"Cannot copy special writable database ... cannot continue");

	FMDatabase *database = [FMDatabase databaseWithPath:temporaryDatabasePath];
	[database open];
	FMDatabase *writableDatabase = [FMDatabase databaseWithPath:writableDatabasePath];
	[writableDatabase open];
	FMDatabase *writableDatabaseSpecial = [FMDatabase databaseWithPath:writableDatabasePathSpecial];
	[writableDatabaseSpecial open];

	NSInteger days[13] = {0,0,0,-1,-1,-2,-2,-3,-3,-4,-11,-33,-46};
	NSArray *insertStatements = @[@"INSERT INTO keystrokes (timestamp, type, keycode, ascii) VALUES('%@', '10', '47', '.');",
								  @"INSERT INTO keystrokes (timestamp, type, keycode, ascii) VALUES('%@', '10', '83', '1');",
								  @"INSERT INTO keystrokes (timestamp, type, keycode, ascii) VALUES('%@', '10', '83', '1');",
								  @"INSERT INTO keystrokes (timestamp, type, keycode, ascii) VALUES('%@', '10', '87', '5');",
								  @"INSERT INTO keystrokes (timestamp, type, keycode, ascii) VALUES('%@', '10', '87', '5');",
								  @"INSERT INTO keystrokes (timestamp, type, keycode, ascii) VALUES('%@', '10', '92', '9');",
								  @"INSERT INTO keystrokes (timestamp, type, keycode, ascii) VALUES('%@', '10', '92', '9');",
								  @"INSERT INTO keystrokes (timestamp, type, keycode, ascii) VALUES('%@', '10', '91', '8');",
								  @"INSERT INTO keystrokes (timestamp, type, keycode, ascii) VALUES('%@', '10', '91', '8');",
								  @"INSERT INTO keystrokes (timestamp, type, keycode, ascii) VALUES('%@', '10', '91', '8');",
								  @"INSERT INTO keystrokes (timestamp, type, keycode, ascii) VALUES('%@', '10', '91', '8');",
								  @"INSERT INTO keystrokes (timestamp, type, keycode, ascii) VALUES('%@', '10', '91', '8');",
								  @"INSERT INTO keystrokes (timestamp, type, keycode, ascii) VALUES('%@', '10', '47', '.');"];

	NSDateFormatter * dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];

	NSDate *currentDate = [NSDate date];
	NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
	NSCalendar *theCalendar = [NSCalendar currentCalendar];
	NSString *dateForInsertion = nil;


	for (int i=0; i<[insertStatements count]; i++) {
		[dayComponent setDay:days[i]];
		dateForInsertion = [dateFormat stringFromDate:[theCalendar dateByAddingComponents:dayComponent toDate:currentDate options:0]];

		[database executeUpdate:[NSString stringWithFormat:[insertStatements objectAtIndex:i], dateForInsertion]];
		[writableDatabase executeUpdate:[NSString stringWithFormat:[insertStatements objectAtIndex:i], dateForInsertion]];
		[writableDatabaseSpecial executeUpdate:[NSString stringWithFormat:[insertStatements objectAtIndex:i], dateForInsertion]];
	}
	[database close];
	[writableDatabase close];
	[writableDatabaseSpecial close];
}

- (void)tearDown{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
	[[NSFileManager defaultManager] removeItemAtPath:temporaryDatabasePath error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:writableDatabasePath error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:writableDatabasePathSpecial error:nil];
}

- (void)testInit{
	YVBKeystrokesDataManager *manager = [[YVBKeystrokesDataManager alloc] init];

	XCTAssertNil([manager queue], @"The queue is not initialized as nil");
	XCTAssertNil([manager filePath], @"The filepath is not initialized as nil");

	XCTAssert([[[manager resultFormatter] thousandSeparator] isEqualToString:@","],
				   @"The formatter doesn't separates on commas");
	XCTAssert([[manager resultFormatter] groupingSize]==3, @"The formatter "
			  "group size is not three");
	XCTAssert([[manager resultFormatter] hasThousandSeparators], @"The "
			  "formatter doesn't have a thousand separator");
}

- (void)testInitWithFilePath{
	YVBKeystrokesDataManager *manager = [[YVBKeystrokesDataManager alloc] initWithFilePath:temporaryDatabasePath];

	XCTAssertNotNil([manager queue], @"The queue is not initialized");
	XCTAssert([[manager filePath] isEqualToString:temporaryDatabasePath],
			  @"The filepath is not initialized correctly");

	XCTAssert([[[manager resultFormatter] thousandSeparator] isEqualToString:@","],
			  @"The formatter doesn't separates on commas");
	XCTAssert([[manager resultFormatter] groupingSize]==3, @"The formatter "
			  "group size is not three");
	XCTAssert([[manager resultFormatter] hasThousandSeparators], @"The "
			  "formatter doesn't have a thousand separator");
}

- (void)testGetTotalCount{
	YVBKeystrokesDataManager *manager = [[YVBKeystrokesDataManager alloc] initWithFilePath:temporaryDatabasePath];
	[manager getTotalCount:^(NSString *result){
		XCTAssert([@"13" isEqualToString:result], @"The total count query is wrong");
	}];
}

- (void)testGetTodayCount{
	YVBKeystrokesDataManager *manager = [[YVBKeystrokesDataManager alloc] initWithFilePath:temporaryDatabasePath];
	[manager getTodayCount:^(NSString *result){
		XCTAssert([@"3" isEqualToString:result], @"The daily count query is wrong");
	}];
}

- (void)testGetWeeklyCount{
	YVBKeystrokesDataManager *manager = [[YVBKeystrokesDataManager alloc] initWithFilePath:temporaryDatabasePath];
	[manager getWeeklyCount:^(NSString *result){
		NSLog(@"The result is %@", result);
		XCTAssert([@"10" isEqualToString:result], @"The weekly count query is wrong");
	}];
}

- (void)testGetMonthlyCount{
	YVBKeystrokesDataManager *manager = [[YVBKeystrokesDataManager alloc] initWithFilePath:temporaryDatabasePath];
	[manager getMonthlyCount:^(NSString *result){
		XCTAssert([@"11" isEqualToString:result], @"The monthly count query is wrong");
	}];
}

- (void)testAddKeystrokeRegularCharacter{
	YVBKeystrokesDataManager *manager = [[YVBKeystrokesDataManager alloc] initWithFilePath:writableDatabasePath];
	[manager addKeystrokeWithTimeStamp:@"2013-12-29 14:44:30" string:@"K" keycode:40 andEventType:10];
	[manager getTotalCount:^(NSString *result){
		XCTAssert([@"14" isEqualToString:result], @"The K keystroke was not added correctly");
	}];

}

- (void)testAddKeystrokeSpecialCharacter{
	YVBKeystrokesDataManager *manager = [[YVBKeystrokesDataManager alloc] initWithFilePath:writableDatabasePathSpecial];
	[manager addKeystrokeWithTimeStamp:@"2013-12-29 14:44:30" string:@"'" keycode:39 andEventType:10];
	[manager getTotalCount:^(NSString *result){
		XCTAssert([@"14" isEqualToString:result], @"The ' keystroke was not added correctly");
	}];

}


@end
