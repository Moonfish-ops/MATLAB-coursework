function S = skillData()
% skillData C/Q/E/X 主动技能配置

    i = 0;

    i=i+1;
    S(i).key='c';
    S(i).id='letsgo';
    S(i).name='Let''s够！';
    S(i).kind='buff';
    S(i).mpCost=20;
    S(i).cd=60*8;
    S(i).duration=60*5;
    S(i).bonusType='fireRate+move';
    S(i).bonusValue=0.45;
    S(i).needUlt=false;

    i=i+1;
    S(i).key='q';
    S(i).id='nice';
    S(i).name='Niceeee';
    S(i).kind='buff';
    S(i).mpCost=25;
    S(i).cd=60*10;
    S(i).duration=60*5;
    S(i).bonusType='dmg';
    S(i).bonusValue=0.35;
    S(i).needUlt=false;

    i=i+1;
    S(i).key='e';
    S(i).id='summondog';
    S(i).name='这么能杀你杀完呗';
    S(i).kind='summon';
    S(i).mpCost=30;
    S(i).cd=60*18;
    S(i).duration=60*12;
    S(i).bonusType='dog';
    S(i).bonusValue=0;
    S(i).needUlt=false;

    i=i+1;
    S(i).key='x';
    S(i).id='ultimate';
    S(i).name='无双';
    S(i).kind='ultimate';
    S(i).mpCost=0;
    S(i).cd=60*25;
    S(i).duration=60*8;
    S(i).bonusType='ult';
    S(i).bonusValue=1.0;
    S(i).needUlt=true;
end
