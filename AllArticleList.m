// 
//  AllArticleList.m
//  spires
//
//  Created by Yuji on 08/10/15.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "AllArticleList.h"
#import "MOC.h"
#import "SpiresHelper.h"
#import "ArticleFetchOperation.h"

static AllArticleList*_allArticleList=nil;
@implementation AllArticleList
{
    ArticleFetchOperation*currentFetchOperation;
}
+(AllArticleList*)allArticleListInMOC:(NSManagedObjectContext*)moc
{
    NSArray* a=nil;
    NSEntityDescription*authorEntity=[NSEntityDescription entityForName:@"AllArticleList" inManagedObjectContext:moc];
    {
	NSFetchRequest*req=[[NSFetchRequest alloc]init];
	[req setEntity:authorEntity];
	NSError*error=nil;
	a=[moc executeFetchRequest:req error:&error];
    }
    if([a count]==1){
	return a[0];
    }else if([a count]>1){
	NSLog(@"inconsistency detected ... there are more than one AllArticleLists!");
        AllArticleList*max=a[0];
	for(NSUInteger i=1;i<[a count];i++){
	    AllArticleList*al=a[i];
            if([al.articles count]>[max.articles count]){
                max=al;
            }
	}
        for(AllArticleList*al in a){
            if(al!=max){
                [moc deleteObject:al];
            }
        }
	return max;
    }else{
	return nil;
    }
}
+(AllArticleList*)createAllArticleListInMOC:(NSManagedObjectContext*)moc
{
    NSEntityDescription*entity=[NSEntityDescription entityForName:@"AllArticleList" inManagedObjectContext:moc];

    AllArticleList* mo=(AllArticleList*)[[NSManagedObject alloc] initWithEntity:entity
				insertIntoManagedObjectContext:nil];
    [mo setValue:@"inspire" forKey:@"name"];
    [mo setValue:@0 forKey:@"positionInView"];
    mo.sortDescriptors=@[[NSSortDescriptor sortDescriptorWithKey:@"eprintForSorting" ascending:NO]];
    [moc insertObject:mo];	
    
    NSEntityDescription*articleEntity=[NSEntityDescription entityForName:@"Article" inManagedObjectContext:moc];
    NSFetchRequest*req=[[NSFetchRequest alloc]init];
    [req setEntity:articleEntity];
    [req setPredicate:[NSPredicate predicateWithValue:YES]];
    [req setFetchLimit:LOADED_ENTRIES_MAX];
    NSError*error=nil;
    NSArray*a=[moc executeFetchRequest:req error:&error];
    NSSet* s=[NSSet setWithArray:a];
    [mo addArticles:s];
    error=nil;
    [moc save:&error];
    return mo;    
}
+(AllArticleList*)allArticleList
{
    if(!_allArticleList){
	_allArticleList=[self allArticleListInMOC:[MOC moc]];
    }
    if(!_allArticleList){
	_allArticleList=[self createAllArticleListInMOC:[MOC moc]];
    }
    return _allArticleList;
}
/*-(void)awakeFromFetch
{
    self.articles=nil;
    [self reload];
}*/
-(NSString*)searchString
{
    return [self primitiveValueForKey:@"searchString"];
}
-(void)setSearchString:(NSString *)newSearchString
{
    [self willChangeValueForKey:@"searchString"];
    [self setPrimitiveValue:newSearchString forKey:@"searchString"];
    if(!newSearchString || [newSearchString isEqualToString:@""]){
        [self reload];
    }
    [self didChangeValueForKey:@"searchString"];
}

-(void)reload //InBackground
{
    NSLog(@"reloading internally:%@",self.searchString);
    if(currentFetchOperation) {
        [currentFetchOperation cancel];
    }
    if([self.articles count]>2000){
        self.articles=nil;
    }
    currentFetchOperation=[[ArticleFetchOperation alloc] initWithQuery:self.searchString forArticleList:self];
    [[OperationQueues sharedQueue] addOperation:currentFetchOperation];
}
/*
-(void)reload // in main thread
{

    if([self.articles count]>2000){
        self.articles=nil;
    }

    NSFetchRequest*req=[[NSFetchRequest alloc] init];
    NSEntityDescription*entity=[NSEntityDescription entityForName:@"Article" inManagedObjectContext:[MOC moc]];
    [req setEntity:entity];
    NSPredicate*predicate=[[SpiresHelper sharedHelper] predicateFromSPIRESsearchString:self.searchString];
    [req setPredicate:predicate];
    [req setIncludesPropertyValues:YES];
    [req setRelationshipKeyPathsForPrefetching:@[@"inLists"]];
    NSError*error;
    NSArray*articles=[[MOC moc] executeFetchRequest:req error:&error];
    [[MOC moc] disableUndo];
    [self addArticles:[NSSet setWithArray:articles]];
    [[MOC moc] enableUndo];
}
 */
-(NSImage*)icon
{
    return [NSImage imageNamed:@"spires-blue"];
}
-(NSString*)placeholderForSearchField
{
    return @"Enter SPIRES query and hit return. Use shift-return to search within local database";
}
@end
